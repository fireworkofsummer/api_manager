import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class ApiProviderManager extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<ApiProvider> _providers = [];
  List<ApiKey> _apiKeys = [];
  SyncConfig? _syncConfig;

  bool _isLoading = false;
  String? _error;

  List<ApiProvider> get providers => _providers;
  List<ApiKey> get apiKeys => _apiKeys;
  SyncConfig? get syncConfig => _syncConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await _initializeDefaultProviders();
    await _initializeAppVersion();
    await loadProviders();
    await loadApiKeys();
    await loadSyncConfig();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadProviders() async {
    try {
      _setLoading(true);
      _setError(null);
      _providers = await _dbService.getAllProviders();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load providers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadApiKeys() async {
    try {
      _setLoading(true);
      _setError(null);
      _apiKeys = await _dbService.getAllApiKeys();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load API keys: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSyncConfig() async {
    try {
      _syncConfig = await _dbService.getSyncConfig();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sync config: $e');
    }
  }

  Future<bool> addProvider(ApiProvider provider) async {
    try {
      _setLoading(true);
      _setError(null);

      final id = await _dbService.insertProvider(provider);
      final newProvider = provider.copyWith(id: id);
      _providers.add(newProvider);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add provider: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProvider(ApiProvider provider) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbService.updateProvider(provider);

      final index = _providers.indexWhere((p) => p.id == provider.id);
      if (index != -1) {
        _providers[index] = provider;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update provider: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProvider(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbService.deleteProvider(id);

      _providers.removeWhere((p) => p.id == id);
      _apiKeys.removeWhere((key) => key.providerId == id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete provider: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addApiKey(ApiKey apiKey) async {
    try {
      _setLoading(true);
      _setError(null);

      final id = await _dbService.insertApiKey(apiKey);
      final newKey = apiKey.copyWith(id: id);
      _apiKeys.insert(0, newKey);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add API key: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateApiKey(ApiKey apiKey) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbService.updateApiKey(apiKey);

      final index = _apiKeys.indexWhere((k) => k.id == apiKey.id);
      if (index != -1) {
        _apiKeys[index] = apiKey;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update API key: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteApiKey(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbService.deleteApiKey(id);

      _apiKeys.removeWhere((k) => k.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete API key: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateApiKeyLastUsed(String id) async {
    try {
      await _dbService.updateApiKeyLastUsed(id);

      final index = _apiKeys.indexWhere((k) => k.id == id);
      if (index != -1) {
        _apiKeys[index] = _apiKeys[index].copyWith(lastUsed: DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update last used: $e');
    }
  }

  Future<bool> saveSyncConfig(SyncConfig config) async {
    try {
      _setLoading(true);
      _setError(null);

      await _dbService.saveSyncConfig(config);
      _syncConfig = config;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save sync config: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<ApiKey> getApiKeysForProvider(String providerId) {
    return _apiKeys.where((key) => key.providerId == providerId).toList();
  }

  ApiProvider? getProviderById(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ApiProvider> get customProviders {
    return _providers.where((p) => p.isCustom).toList();
  }

  List<ApiProvider> get defaultProviders {
    return _providers.where((p) => !p.isCustom).toList();
  }

  Future<void> _initializeDefaultProviders() async {
    final defaultProviders = _getDefaultProviders();

    for (final provider in defaultProviders) {
      final existing = await _dbService.getProviderById(provider.id);
      if (existing == null) {
        await _dbService.insertProvider(provider);
      }
    }
  }

  List<ApiProvider> _getDefaultProviders() {
    return [
      ApiProvider(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'anthropic',
        name: 'Anthropic',
        baseUrl: 'https://api.anthropic.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'google',
        name: 'Google AI',
        baseUrl: 'https://generativelanguage.googleapis.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'cohere',
        name: 'Cohere',
        baseUrl: 'https://api.cohere.ai/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'mistral',
        name: 'Mistral AI',
        baseUrl: 'https://api.mistral.ai/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'huggingface',
        name: 'Hugging Face',
        baseUrl: 'https://api-inference.huggingface.co',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'baichuan',
        name: '百川智能',
        baseUrl: 'https://api.baichuan-ai.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'zhipu',
        name: '智谱AI',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'moonshot',
        name: 'Moonshot AI',
        baseUrl: 'https://api.moonshot.cn/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'alibaba',
        name: '阿里云',
        baseUrl: 'https://dashscope.aliyuncs.com/api/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'tencent',
        name: '腾讯云',
        baseUrl: 'https://hunyuan.tencentcloudapi.com',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ApiProvider(
        id: 'xunfei',
        name: '科大讯飞',
        baseUrl: 'https://spark-api.xf-yun.com/v1',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<SyncConfig?> getSyncConfig() async {
    return await _dbService.getSyncConfig();
  }

  Future<void> _initializeAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 更新数据库中的应用版本信息
      await _dbService.updateAppVersion(
        packageInfo.version,
        currentBuildNumber,
      );
    } catch (e) {
      print('Failed to initialize app version: $e');
    }
  }
}
