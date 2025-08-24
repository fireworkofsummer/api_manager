import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

class UpdateService {
  static const String updateCheckUrl =
      'https://api.github.com/repos/fireworkofsummer/api_manager/releases/latest';
  static const String manualDownloadUrl =
      'https://github.com/fireworkofsummer/api_manager/releases';

  Future<PackageInfo> getCurrentAppInfo() async {
    return await PackageInfo.fromPlatform();
  }

  Future<AppVersion?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(updateCheckUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGitHubRelease(data);
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  AppVersion _parseGitHubRelease(Map<String, dynamic> data) {
    final tagName = data['tag_name'] as String;
    final version = tagName.replaceFirst('v', '');

    // 从assets中查找适合当前平台的下载链接
    final assets = data['assets'] as List;
    String downloadUrl = '';

    if (Platform.isWindows) {
      final windowsAsset = assets.firstWhere(
        (asset) =>
            (asset['name'] as String).toLowerCase().contains('windows') &&
            (asset['name'] as String).toLowerCase().contains('.zip'),
        orElse: () => null,
      );
      downloadUrl = windowsAsset?['browser_download_url'] ?? '';
    } else if (Platform.isAndroid) {
      final androidAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).toLowerCase().endsWith('.apk'),
        orElse: () => null,
      );
      downloadUrl = androidAsset?['browser_download_url'] ?? '';
    }

    return AppVersion(
      version: version,
      buildNumber: _extractBuildNumber(version),
      downloadUrl: downloadUrl,
      releaseNotes: data['body'] as String?,
      isForceUpdate: _isForceUpdate(data['body'] as String?),
      releaseDate: DateTime.parse(data['published_at'] as String),
    );
  }

  int _extractBuildNumber(String version) {
    // 假设版本格式为 "1.0.0+1" 或 "1.0.0"
    final parts = version.split('+');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 1;
    }
    // 如果没有build number，返回默认值1
    return 1;
  }

  bool _isForceUpdate(String? releaseNotes) {
    if (releaseNotes == null) return false;
    return releaseNotes.toLowerCase().contains('[force-update]') ||
        releaseNotes.toLowerCase().contains('强制更新');
  }

  Future<bool> hasNewVersion() async {
    final currentInfo = await getCurrentAppInfo();
    final latestVersion = await checkForUpdates();

    if (latestVersion == null) return false;

    final currentBuildNumber = int.tryParse(currentInfo.buildNumber) ?? 1;
    return latestVersion.isNewerThan(currentInfo.version, currentBuildNumber);
  }

  Future<bool> downloadAndInstallUpdate(
    AppVersion appVersion, {
    Function(double)? onProgress,
  }) async {
    if (Platform.isAndroid) {
      return await _downloadAndInstallAndroid(
        appVersion,
        onProgress: onProgress,
      );
    } else if (Platform.isWindows) {
      return await _downloadAndInstallWindows(
        appVersion,
        onProgress: onProgress,
      );
    }
    return false;
  }

  Future<bool> _downloadAndInstallAndroid(
    AppVersion appVersion, {
    Function(double)? onProgress,
  }) async {
    try {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manageExternal = await Permission.manageExternalStorage.request();
        if (!manageExternal.isGranted) {
          return false;
        }
      }

      // 下载APK文件
      final downloadPath = await _downloadFile(
        appVersion.downloadUrl,
        'api_manager_${appVersion.version}.apk',
        onProgress: onProgress,
      );

      if (downloadPath != null) {
        // 安装APK
        return await _installApk(downloadPath);
      }
    } catch (e) {
      print('Error downloading/installing Android update: $e');
    }
    return false;
  }

  Future<bool> _downloadAndInstallWindows(
    AppVersion appVersion, {
    Function(double)? onProgress,
  }) async {
    try {
      // Windows平台直接打开下载链接让用户手动下载安装
      final uri = Uri.parse(appVersion.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      print('Error launching Windows download: $e');
    }
    return false;
  }

  Future<String?> _downloadFile(
    String url,
    String filename, {
    Function(double)? onProgress,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // 获取下载目录
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = path.join(downloadsDir.path, filename);
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        onProgress?.call(1.0);
        return filePath;
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
    return null;
  }

  Future<bool> _installApk(String apkPath) async {
    try {
      // 请求安装权限
      final installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        return false;
      }

      // 使用Intent安装APK
      final uri = Uri.parse('file://$apkPath');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      print('Error installing APK: $e');
    }
    return false;
  }

  Future<void> openManualDownloadPage() async {
    final uri = Uri.parse(manualDownloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
