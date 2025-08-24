class AppVersion {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isForceUpdate;
  final DateTime releaseDate;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.releaseNotes,
    this.isForceUpdate = false,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      downloadUrl: json['downloadUrl'] as String,
      releaseNotes: json['releaseNotes'] as String?,
      isForceUpdate: json['isForceUpdate'] as bool? ?? false,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'isForceUpdate': isForceUpdate,
      'releaseDate': releaseDate.toIso8601String(),
    };
  }

  bool isNewerThan(String currentVersion, int currentBuildNumber) {
    final currentVersionParts = currentVersion
        .split('.')
        .map(int.parse)
        .toList();
    final newVersionParts = version.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final current = i < currentVersionParts.length
          ? currentVersionParts[i]
          : 0;
      final newVer = i < newVersionParts.length ? newVersionParts[i] : 0;

      if (newVer > current) return true;
      if (newVer < current) return false;
    }

    return buildNumber > currentBuildNumber;
  }
}
