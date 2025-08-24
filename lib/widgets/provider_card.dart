import 'package:flutter/material.dart';
import '../models/models.dart';

class ProviderCard extends StatelessWidget {
  final ApiProvider provider;
  final int keyCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.keyCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getProviderColor(provider.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: provider.iconUrl != null && provider.iconUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          provider.iconUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getProviderIcon(provider.name),
                            color: _getProviderColor(provider.name),
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        _getProviderIcon(provider.name),
                        color: _getProviderColor(provider.name),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.baseUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.key,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$keyCount 个密钥',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.isCustom) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProviderIcon(String name) {
    switch (name.toLowerCase()) {
      case 'openai':
        return Icons.smart_toy;
      case 'anthropic':
        return Icons.psychology;
      case 'google ai':
      case 'google':
        return Icons.assistant;
      case 'cohere':
        return Icons.chat;
      case 'hugging face':
        return Icons.face;
      case 'azure':
        return Icons.cloud;
      case 'aws':
        return Icons.cloud_queue;
      case 'mistral ai':
      case 'mistral':
        return Icons.wind_power;
      case 'deepseek':
        return Icons.visibility;
      case '百川智能':
      case 'baichuan':
        return Icons.waves;
      case '智谱ai':
      case 'zhipu':
        return Icons.lightbulb;
      case 'moonshot ai':
      case 'moonshot':
        return Icons.rocket_launch;
      case '阿里云':
      case 'alibaba':
        return Icons.cloud_circle;
      case '腾讯云':
      case 'tencent':
        return Icons.cloud_sync;
      case '科大讯飞':
      case 'xunfei':
        return Icons.mic;
      default:
        return Icons.api;
    }
  }

  Color _getProviderColor(String name) {
    switch (name.toLowerCase()) {
      case 'openai':
        return const Color(0xFF00A67E);
      case 'anthropic':
        return const Color(0xFFD97706);
      case 'google ai':
      case 'google':
        return const Color(0xFF4285F4);
      case 'cohere':
        return const Color(0xFF39C5BB);
      case 'hugging face':
        return const Color(0xFFFFD21E);
      case 'azure':
        return const Color(0xFF0078D4);
      case 'aws':
        return const Color(0xFFFF9900);
      case 'mistral ai':
      case 'mistral':
        return const Color(0xFFFF7C00);
      case 'deepseek':
        return const Color(0xFF6C5CE7);
      case '百川智能':
      case 'baichuan':
        return const Color(0xFF00D4AA);
      case '智谱ai':
      case 'zhipu':
        return const Color(0xFF2ECC71);
      case 'moonshot ai':
      case 'moonshot':
        return const Color(0xFF9B59B6);
      case '阿里云':
      case 'alibaba':
        return const Color(0xFFFF6C00);
      case '腾讯云':
      case 'tencent':
        return const Color(0xFF00A9FF);
      case '科大讯飞':
      case 'xunfei':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6366F1);
    }
  }
}