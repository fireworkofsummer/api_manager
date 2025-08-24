class SyncConfig {
  final String? webdavUrl;
  final String? username;
  final String? password;
  final bool autoSync;
  final int syncInterval;
  final DateTime? lastSyncAt;

  SyncConfig({
    this.webdavUrl,
    this.username,
    this.password,
    this.autoSync = false,
    this.syncInterval = 300,
    this.lastSyncAt,
  });

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      webdavUrl: json['webdavUrl'],
      username: json['username'],
      password: json['password'],
      autoSync: (json['autoSync'] as int? ?? 0) == 1,
      syncInterval: json['syncInterval'] ?? 300,
      lastSyncAt: json['lastSyncAt'] != null ? DateTime.parse(json['lastSyncAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'webdavUrl': webdavUrl,
      'username': username,
      'password': password,
      'autoSync': autoSync ? 1 : 0,
      'syncInterval': syncInterval,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  SyncConfig copyWith({
    String? webdavUrl,
    String? username,
    String? password,
    bool? autoSync,
    int? syncInterval,
    DateTime? lastSyncAt,
  }) {
    return SyncConfig(
      webdavUrl: webdavUrl ?? this.webdavUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  bool get isConfigured {
    return webdavUrl != null && 
           webdavUrl!.isNotEmpty && 
           username != null && 
           username!.isNotEmpty && 
           password != null && 
           password!.isNotEmpty;
  }

  @override
  String toString() {
    return 'SyncConfig(webdavUrl: $webdavUrl, username: $username, autoSync: $autoSync)';
  }
}