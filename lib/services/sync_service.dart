import 'dart:convert';
import 'package:webdav_client/webdav_client.dart';
import '../models/models.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _dbService = DatabaseService();
  Client? _client;
  SyncConfig? _config;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  static const String _dataFileName = 'api_manager_data.json';
  static const String _folderPath = 'api_manager';

  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (config.isConfigured) {
      _client = newClient(
        config.webdavUrl!,
        user: config.username!,
        password: config.password!,
      );
    }
  }

  Future<bool> testConnection(SyncConfig config) async {
    try {
      final client = newClient(
        config.webdavUrl!,
        user: config.username!,
        password: config.password!,
      );
      
      await client.ping();
      
      // 测试目录创建权限
      await _ensureDirectoryExists(client);
      
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<SyncResult> syncData() async {
    if (_isSyncing || _client == null || _config == null) {
      return SyncResult(
        success: false,
        message: _isSyncing 
          ? 'Sync already in progress' 
          : 'Sync not configured',
      );
    }

    _isSyncing = true;
    
    try {
      final localData = await _getLocalData();
      final remoteExists = await _remoteFileExists();
      
      if (!remoteExists) {
        return await _uploadData(localData);
      }
      
      final remoteData = await _downloadData();
      if (remoteData == null) {
        return SyncResult(
          success: false,
          message: 'Failed to download remote data',
        );
      }
      
      final mergedData = await _mergeData(localData, remoteData);
      await _saveLocalData(mergedData);
      await _uploadData(mergedData);
      
      await _updateLastSyncTime();
      
      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
      );
      
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> uploadData() async {
    if (_isSyncing || _client == null) {
      return SyncResult(
        success: false,
        message: _isSyncing 
          ? 'Sync already in progress' 
          : 'Sync not configured',
      );
    }

    _isSyncing = true;
    
    try {
      final localData = await _getLocalData();
      final result = await _uploadData(localData);
      await _updateLastSyncTime();
      return result;
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Upload failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> downloadData() async {
    if (_isSyncing || _client == null) {
      return SyncResult(
        success: false,
        message: _isSyncing 
          ? 'Sync already in progress' 
          : 'Sync not configured',
      );
    }

    _isSyncing = true;
    
    try {
      final remoteData = await _downloadData();
      if (remoteData == null) {
        return SyncResult(
          success: false,
          message: 'No remote data found',
        );
      }
      
      await _saveLocalData(remoteData);
      await _updateLastSyncTime();
      
      return SyncResult(
        success: true,
        message: 'Download completed successfully',
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Download failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncData> _getLocalData() async {
    final providers = await _dbService.getAllProviders();
    final apiKeys = await _dbService.getAllApiKeys();
    
    return SyncData(
      providers: providers,
      apiKeys: apiKeys,
      lastModified: DateTime.now(),
    );
  }

  Future<bool> _remoteFileExists() async {
    final filePath = '$_folderPath/$_dataFileName';
    
    try {
      await _ensureDirectoryExists(_client!);
      await _client!.read(filePath);
      return true;
    } catch (e) {
      print('Remote file check failed for $filePath: $e');
      
      // 回退策略：检查根目录
      try {
        await _client!.read(_dataFileName);
        print('Found file in root directory');
        return true;
      } catch (rootError) {
        print('File not found in root either: $rootError');
        return false;
      }
    }
  }

  Future<SyncData?> _downloadData() async {
    try {
      await _ensureDirectoryExists(_client!);
      final filePath = '$_folderPath/$_dataFileName';
      
      List<int> response;
      try {
        response = await _client!.read(filePath);
        print('Downloaded from: $filePath');
      } catch (e) {
        print('Download from $filePath failed: $e');
        
        // 回退策略：从根目录下载
        print('Trying fallback: downloading from root directory');
        response = await _client!.read(_dataFileName);
        print('Fallback download successful from root');
      }
      
      final jsonData = json.decode(utf8.decode(response));
      return SyncData.fromJson(jsonData);
    } catch (e) {
      print('Download failed: $e');
      return null;
    }
  }

  Future<SyncResult> _uploadData(SyncData data) async {
    try {
      await _ensureDirectoryExists(_client!);
      
      final jsonData = json.encode(data.toJson());
      final bytes = utf8.encode(jsonData);
      final filePath = '$_folderPath/$_dataFileName';
      
      // 尝试上传，如果失败则尝试不同的路径
      try {
        await _client!.write(filePath, bytes);
        print('Upload successful to: $filePath');
      } catch (e) {
        print('Upload to $filePath failed: $e');
        
        // 回退策略：尝试直接写入根目录
        print('Trying fallback: writing to root directory');
        await _client!.write(_dataFileName, bytes);
        print('Fallback upload successful to root');
      }
      
      return SyncResult(
        success: true,
        message: 'Data uploaded successfully',
      );
    } catch (e) {
      print('Upload failed details: $e');
      
      // 提供更详细的错误信息
      String errorMessage = 'Upload failed: ';
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMessage += 'Directory not found or no write permission. Please check WebDAV path and permissions.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage += 'Authentication failed. Please check username and password.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage += 'Permission denied. Please check write permissions on WebDAV server.';
      } else {
        errorMessage += e.toString();
      }
      
      return SyncResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  Future<SyncData> _mergeData(SyncData local, SyncData remote) async {
    final mergedProviders = <String, ApiProvider>{};
    final mergedApiKeys = <String, ApiKey>{};

    for (final provider in local.providers) {
      mergedProviders[provider.id] = provider;
    }

    for (final provider in remote.providers) {
      final existing = mergedProviders[provider.id];
      if (existing == null || provider.updatedAt.isAfter(existing.updatedAt)) {
        mergedProviders[provider.id] = provider;
      }
    }

    for (final key in local.apiKeys) {
      mergedApiKeys[key.id] = key;
    }

    for (final key in remote.apiKeys) {
      final existing = mergedApiKeys[key.id];
      if (existing == null || key.updatedAt.isAfter(existing.updatedAt)) {
        mergedApiKeys[key.id] = key;
      }
    }

    return SyncData(
      providers: mergedProviders.values.toList(),
      apiKeys: mergedApiKeys.values.toList(),
      lastModified: DateTime.now(),
    );
  }

  Future<void> _saveLocalData(SyncData data) async {
    final db = await _dbService.database;
    
    await db.transaction((txn) async {
      await txn.delete('providers');
      await txn.delete('api_keys');
      
      for (final provider in data.providers) {
        await txn.insert('providers', provider.toJson());
      }
      
      for (final apiKey in data.apiKeys) {
        await txn.insert('api_keys', apiKey.toJson());
      }
    });
  }

  Future<void> _updateLastSyncTime() async {
    if (_config != null) {
      final updatedConfig = _config!.copyWith(lastSyncAt: DateTime.now());
      await _dbService.saveSyncConfig(updatedConfig);
      _config = updatedConfig;
    }
  }

  Future<void> _ensureDirectoryExists(Client client) async {
    try {
      // 检查目录是否存在
      await client.readDir(_folderPath);
    } catch (e) {
      // 目录不存在，尝试创建
      try {
        await client.mkdir(_folderPath);
        print('Created directory: $_folderPath');
      } catch (createError) {
        print('Failed to create directory $_folderPath: $createError');
        // 有些WebDAV服务器可能不需要显式创建目录，继续尝试
      }
    }
  }
}

class SyncData {
  final List<ApiProvider> providers;
  final List<ApiKey> apiKeys;
  final DateTime lastModified;

  SyncData({
    required this.providers,
    required this.apiKeys,
    required this.lastModified,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      providers: (json['providers'] as List)
          .map((e) => ApiProvider.fromJson(e))
          .toList(),
      apiKeys: (json['apiKeys'] as List)
          .map((e) => ApiKey.fromJson(e))
          .toList(),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providers': providers.map((e) => e.toJson()).toList(),
      'apiKeys': apiKeys.map((e) => e.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

class SyncResult {
  final bool success;
  final String message;

  SyncResult({
    required this.success,
    required this.message,
  });
}