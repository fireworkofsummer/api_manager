import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../models/models.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppVersion appVersion;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.appVersion,
    required this.currentVersion,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  final UpdateService _updateService = UpdateService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: widget.appVersion.isForceUpdate
                ? Colors.orange
                : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            widget.appVersion.isForceUpdate ? '强制更新' : '发现新版本',
            style: TextStyle(
              color: widget.appVersion.isForceUpdate
                  ? Colors.orange
                  : Colors.blue,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionInfo(),
            const SizedBox(height: 16),
            if (widget.appVersion.releaseNotes != null) ...[
              _buildReleaseNotes(),
              const SizedBox(height: 16),
            ],
            if (_isDownloading) _buildDownloadProgress(),
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前版本',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                widget.currentVersion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最新版本',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                widget.appVersion.version,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('更新内容', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.appVersion.releaseNotes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('下载进度', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          _downloadStatus,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isDownloading) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('后台下载'),
        ),
      ];
    }

    return [
      if (!widget.appVersion.isForceUpdate)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后提醒'),
        ),
      TextButton(onPressed: _openManualDownload, child: const Text('手动下载')),
      FilledButton(onPressed: _startDownload, child: const Text('立即更新')),
    ];
  }

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = '正在下载...';
    });

    try {
      final success = await _updateService.downloadAndInstallUpdate(
        widget.appVersion,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = '下载进度: ${(progress * 100).toInt()}%';
          });
          _progressController.animateTo(progress);
        },
      );

      if (success) {
        setState(() {
          _downloadStatus = '下载完成，准备安装...';
        });

        // 显示安装提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('下载完成，请查看通知栏安装更新'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _downloadStatus = '下载失败，请尝试手动下载';
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _downloadStatus = '下载出错: $e';
        _isDownloading = false;
      });
    }
  }

  void _openManualDownload() async {
    await _updateService.openManualDownloadPage();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

// 更新检查函数
Future<void> checkForUpdatesAndShow(BuildContext context) async {
  final updateService = UpdateService();

  try {
    final currentInfo = await updateService.getCurrentAppInfo();
    final latestVersion = await updateService.checkForUpdates();

    if (latestVersion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('检查更新失败，请稍后重试')));
      return;
    }

    final currentBuildNumber = int.tryParse(currentInfo.buildNumber) ?? 1;
    final hasUpdate = latestVersion.isNewerThan(
      currentInfo.version,
      currentBuildNumber,
    );

    if (!hasUpdate) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前已是最新版本')));
      return;
    }

    // 显示更新对话框
    showModal<void>(
      context: context,
      builder: (context) => UpdateDialog(
        appVersion: latestVersion,
        currentVersion: currentInfo.version,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('检查更新出错: $e')));
  }
}
