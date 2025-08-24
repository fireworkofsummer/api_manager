import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncService _syncService = SyncService();

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProviderManager>(
      builder: (context, apiProvider, child) {
        final syncConfig = apiProvider.syncConfig;

        if (syncConfig == null || !syncConfig.isConfigured) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                _syncService.isSyncing ? Icons.sync : Icons.cloud_done,
                size: 16,
                color: _syncService.isSyncing
                    ? Theme.of(context).colorScheme.primary
                    : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSyncStatusText(syncConfig),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (!_syncService.isSyncing) ...[
                TextButton(
                  onPressed: () => _performSync(apiProvider),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                  ),
                  child: const Text('立即同步'),
                ),
              ] else ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getSyncStatusText(syncConfig) {
    if (_syncService.isSyncing) {
      return '同步中...';
    }

    if (syncConfig.lastSyncAt != null) {
      final timeSince = DateTime.now().difference(syncConfig.lastSyncAt!);
      if (timeSince.inDays > 0) {
        return '上次同步: ${timeSince.inDays}天前';
      } else if (timeSince.inHours > 0) {
        return '上次同步: ${timeSince.inHours}小时前';
      } else if (timeSince.inMinutes > 0) {
        return '上次同步: ${timeSince.inMinutes}分钟前';
      } else {
        return '刚刚同步';
      }
    }

    return '从未同步';
  }

  Future<void> _performSync(ApiProviderManager apiProvider) async {
    final syncConfig = apiProvider.syncConfig;
    if (syncConfig == null || !syncConfig.isConfigured) return;

    setState(() {});

    await _syncService.initialize(syncConfig);
    final result = await _syncService.syncData();

    setState(() {});

    if (!mounted) return;

    if (result.success) {
      await apiProvider.loadProviders();
      await apiProvider.loadApiKeys();
      await apiProvider.loadSyncConfig();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
