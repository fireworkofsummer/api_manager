import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/api_provider.dart';
import '../services/sync_service.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _autoSync = false;
  int _syncInterval = 300;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _passwordVisible = false;
  String? _lastSyncTime;

  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    final apiProvider = context.read<ApiProviderManager>();
    final config = await apiProvider.getSyncConfig();

    if (config != null && mounted) {
      setState(() {
        _urlController.text = config.webdavUrl ?? '';
        _usernameController.text = config.username ?? '';
        _passwordController.text = config.password ?? '';
        _autoSync = config.autoSync;
        _syncInterval = config.syncInterval;
        _lastSyncTime = config.lastSyncAt?.toString();
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final config = SyncConfig(
      webdavUrl: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    try {
      final success = await _syncService.testConnection(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接成功！' : '连接失败，请检查配置'),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接测试失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final config = SyncConfig(
      webdavUrl: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      autoSync: _autoSync,
      syncInterval: _syncInterval,
    );

    try {
      final apiProvider = context.read<ApiProviderManager>();
      await apiProvider.saveSyncConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('同步配置已保存')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performSync() async {
    setState(() => _isLoading = true);

    try {
      final result = await _syncService.syncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );

        if (result.success) {
          await _loadCurrentConfig();
          await context.read<ApiProviderManager>().loadProviders();
          await context.read<ApiProviderManager>().loadApiKeys();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_urlController.text.isNotEmpty &&
              _usernameController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isLoading ? null : _performSync,
              tooltip: '立即同步',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildConnectionSection(),
            const SizedBox(height: 24),
            _buildSyncSettingsSection(),
            const SizedBox(height: 24),
            _buildActionsSection(),
            if (_lastSyncTime != null) ...[
              const SizedBox(height: 24),
              _buildLastSyncSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WebDAV 连接', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'WebDAV URL',
                hintText: 'https://example.com/webdav',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入WebDAV URL';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme) {
                  return '请输入有效的URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_protected_setup),
                label: Text(_isTesting ? '测试中...' : '测试连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同步设置', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('自动同步'),
              subtitle: const Text('定期自动同步数据'),
              value: _autoSync,
              onChanged: (value) {
                setState(() => _autoSync = value);
              },
            ),
            if (_autoSync) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('同步间隔'),
                subtitle: Text(_getSyncIntervalText()),
                trailing: DropdownButton<int>(
                  value: _syncInterval,
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('1分钟')),
                    DropdownMenuItem(value: 300, child: Text('5分钟')),
                    DropdownMenuItem(value: 600, child: Text('10分钟')),
                    DropdownMenuItem(value: 1800, child: Text('30分钟')),
                    DropdownMenuItem(value: 3600, child: Text('1小时')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _syncInterval = value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveConfig,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? '保存中...' : '保存配置'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _showSyncOptions('upload'),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('上传数据'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _showSyncOptions('download'),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('下载数据'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSyncSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同步状态', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('上次同步时间'),
              subtitle: Text(_lastSyncTime ?? '从未同步'),
            ),
          ],
        ),
      ),
    );
  }

  String _getSyncIntervalText() {
    switch (_syncInterval) {
      case 60:
        return '每1分钟';
      case 300:
        return '每5分钟';
      case 600:
        return '每10分钟';
      case 1800:
        return '每30分钟';
      case 3600:
        return '每1小时';
      default:
        return '${_syncInterval}秒';
    }
  }

  void _showSyncOptions(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'upload' ? '上传数据' : '下载数据'),
        content: Text(
          type == 'upload'
              ? '这将把本地数据上传到云端，覆盖云端数据。确定继续吗？'
              : '这将用云端数据覆盖本地数据。本地修改将丢失。确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (type == 'upload') {
                _performUpload();
              } else {
                _performDownload();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpload() async {
    setState(() => _isLoading = true);

    try {
      final result = await _syncService.uploadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );

        if (result.success) {
          await _loadCurrentConfig();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performDownload() async {
    setState(() => _isLoading = true);

    try {
      final result = await _syncService.downloadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );

        if (result.success) {
          await _loadCurrentConfig();
          await context.read<ApiProviderManager>().loadProviders();
          await context.read<ApiProviderManager>().loadApiKeys();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
