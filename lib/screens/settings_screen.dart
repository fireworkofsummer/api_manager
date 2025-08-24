import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/database_service.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _dbService = DatabaseService();

  Map<String, dynamic>? _appSettings;
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _dbService.getAppSettings();
      final packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _appSettings =
            settings ?? {'autoCheckUpdates': 1, 'downloadUpdatesOnWifi': 1};
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载设置失败: $e')));
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final updatedSettings = Map<String, dynamic>.from(_appSettings!);
      updatedSettings[key] = value is bool ? (value ? 1 : 0) : value;

      await _dbService.updateAppSettings(updatedSettings);

      setState(() {
        _appSettings = updatedSettings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新设置失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('应用设置'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [_buildUpdateSection(), _buildAboutSection()]),
    );
  }

  Widget _buildUpdateSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '更新设置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('自动检查更新'),
            subtitle: const Text('启动时自动检查是否有新版本'),
            value: (_appSettings?['autoCheckUpdates'] ?? 1) == 1,
            onChanged: (value) => _updateSetting('autoCheckUpdates', value),
          ),
          SwitchListTile(
            title: const Text('仅在WiFi下载载更新'),
            subtitle: const Text('避免消耗移动数据流量'),
            value: (_appSettings?['downloadUpdatesOnWifi'] ?? 1) == 1,
            onChanged: (value) =>
                _updateSetting('downloadUpdatesOnWifi', value),
          ),
          ListTile(
            title: const Text('检查更新'),
            subtitle: Text(_getLastUpdateCheckText()),
            trailing: const Icon(Icons.system_update),
            onTap: () => checkForUpdatesAndShow(context),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '关于应用',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('应用名称'),
            subtitle: Text(_packageInfo?.appName ?? 'API Manager'),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('当前版本'),
            subtitle: Text(
              '${_packageInfo?.version ?? '1.0.0'} (${_packageInfo?.buildNumber ?? '1'})',
            ),
            leading: const Icon(Icons.tag),
          ),
          ListTile(
            title: const Text('包名'),
            subtitle: Text(
              _packageInfo?.packageName ?? 'com.example.api_manager',
            ),
            leading: const Icon(Icons.code),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('开源许可'),
            subtitle: const Text('查看第三方开源库'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLicensePage(),
          ),
        ],
      ),
    );
  }

  String _getLastUpdateCheckText() {
    final lastCheck = _appSettings?['lastUpdateCheck'];
    if (lastCheck == null) {
      return '从未检查过更新';
    }

    try {
      final lastCheckDate = DateTime.parse(lastCheck);
      final now = DateTime.now();
      final difference = now.difference(lastCheckDate);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '未知';
    }
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: _packageInfo?.appName ?? 'API Manager',
      applicationVersion: _packageInfo?.version ?? '1.0.0',
      applicationLegalese: '© 2024 API Manager. All rights reserved.',
    );
  }
}
