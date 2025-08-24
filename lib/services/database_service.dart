import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'api_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE providers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        baseUrl TEXT NOT NULL,
        iconUrl TEXT,
        isCustom INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE api_keys (
        id TEXT PRIMARY KEY,
        providerId TEXT NOT NULL,
        keyValue TEXT NOT NULL,
        alias TEXT,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastUsed TEXT,
        FOREIGN KEY (providerId) REFERENCES providers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        webdavUrl TEXT,
        username TEXT,
        password TEXT,
        autoSync INTEGER NOT NULL DEFAULT 0,
        syncInterval INTEGER NOT NULL DEFAULT 300,
        lastSyncAt TEXT
      )
    ''');

    await _insertDefaultProviders(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  Future<void> _insertDefaultProviders(Database db) async {
    // Skip inserting default providers here since they are managed by ApiProviderManager
  }

  Future<List<ApiProvider>> getAllProviders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('providers', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => ApiProvider.fromJson(maps[i]));
  }

  Future<ApiProvider?> getProviderById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'providers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return ApiProvider.fromJson(maps.first);
    }
    return null;
  }

  Future<String> insertProvider(ApiProvider provider) async {
    final db = await database;
    final providerWithId = provider.copyWith(
      id: provider.id.isEmpty ? _uuid.v4() : provider.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await db.insert('providers', providerWithId.toJson());
    return providerWithId.id;
  }

  Future<void> updateProvider(ApiProvider provider) async {
    final db = await database;
    final updatedProvider = provider.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      'providers',
      updatedProvider.toJson(),
      where: 'id = ?',
      whereArgs: [provider.id],
    );
  }

  Future<void> deleteProvider(String id) async {
    final db = await database;
    await db.delete('providers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ApiKey>> getAllApiKeys() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('api_keys', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => ApiKey.fromJson(maps[i]));
  }

  Future<List<ApiKey>> getApiKeysByProvider(String providerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_keys',
      where: 'providerId = ?',
      whereArgs: [providerId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => ApiKey.fromJson(maps[i]));
  }

  Future<ApiKey?> getApiKey(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_keys',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return ApiKey.fromJson(maps.first);
    }
    return null;
  }

  Future<String> insertApiKey(ApiKey apiKey) async {
    final db = await database;
    final keyWithId = apiKey.copyWith(
      id: apiKey.id.isEmpty ? _uuid.v4() : apiKey.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await db.insert('api_keys', keyWithId.toJson());
    return keyWithId.id;
  }

  Future<void> updateApiKey(ApiKey apiKey) async {
    final db = await database;
    final updatedKey = apiKey.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      'api_keys',
      updatedKey.toJson(),
      where: 'id = ?',
      whereArgs: [apiKey.id],
    );
  }

  Future<void> deleteApiKey(String id) async {
    final db = await database;
    await db.delete('api_keys', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateApiKeyLastUsed(String id) async {
    final db = await database;
    await db.update(
      'api_keys',
      {'lastUsed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SyncConfig?> getSyncConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sync_config');
    
    if (maps.isNotEmpty) {
      return SyncConfig.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    final db = await database;
    await db.insert(
      'sync_config',
      {'id': 1, ...config.toJson()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}