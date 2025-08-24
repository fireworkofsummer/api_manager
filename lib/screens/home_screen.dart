import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart' as providers;
import '../widgets/api_key_card.dart';
import '../widgets/provider_card.dart';
import '../widgets/sync_status_widget.dart';
import '../screens/add_api_key_screen.dart';
import '../screens/add_provider_screen.dart';
import '../screens/sync_settings_screen.dart';
import '../screens/provider_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<providers.ApiProviderManager>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('API 管理器'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'API 密钥'),
            Tab(text: '供应商'),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusWidget(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApiKeysTab(),
                _buildProvidersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            _showAddApiKeyDialog();
          } else {
            _showAddProviderDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApiKeysTab() {
    return Consumer<providers.ApiProviderManager>(
      builder: (context, apiProvider, child) {
        if (apiProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (apiProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '错误: ${apiProvider.error}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => apiProvider.loadApiKeys(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (apiProvider.apiKeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.key_off,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(height: 16),
                Text(
                  '没有 API 密钥',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击 + 按钮添加您的第一个 API 密钥',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => apiProvider.loadApiKeys(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: apiProvider.apiKeys.length,
            itemBuilder: (context, index) {
              final apiKey = apiProvider.apiKeys[index];
              final provider = apiProvider.getProviderById(apiKey.providerId);
              
              return ApiKeyCard(
                apiKey: apiKey,
                provider: provider,
                onEdit: () => _editApiKey(apiKey),
                onDelete: () => _deleteApiKey(apiKey),
                onToggleActive: () => _toggleApiKeyActive(apiKey),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProvidersTab() {
    return Consumer<providers.ApiProviderManager>(
      builder: (context, apiProvider, child) {
        if (apiProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (apiProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '错误: ${apiProvider.error}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => apiProvider.loadProviders(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (apiProvider.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(height: 16),
                Text(
                  '没有供应商',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击 + 按钮添加自定义供应商',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final defaultProviders = apiProvider.defaultProviders;
        final customProviders = apiProvider.customProviders;

        return RefreshIndicator(
          onRefresh: () => apiProvider.loadProviders(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (defaultProviders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '内置供应商',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...defaultProviders.map((provider) {
                  final keyCount = apiProvider.getApiKeysForProvider(provider.id).length;
                  return ProviderCard(
                    provider: provider,
                    keyCount: keyCount,
                    onTap: () => _showProviderDetails(provider),
                    onEdit: null,
                    onDelete: () => _deleteProvider(provider),
                  );
                }),
              ],
              if (customProviders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '自定义供应商',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...customProviders.map((provider) {
                  final keyCount = apiProvider.getApiKeysForProvider(provider.id).length;
                  return ProviderCard(
                    provider: provider,
                    keyCount: keyCount,
                    onTap: () => _showProviderDetails(provider),
                    onEdit: () => _editProvider(provider),
                    onDelete: () => _deleteProvider(provider),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddApiKeyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddApiKeyScreen(),
      ),
    );
  }

  void _showAddProviderDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProviderScreen(),
      ),
    );
  }

  void _editApiKey(apiKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddApiKeyScreen(apiKey: apiKey),
      ),
    );
  }

  void _deleteApiKey(apiKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除 API 密钥'),
        content: Text('确定要删除 "${apiKey.alias ?? apiKey.maskedKey}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<providers.ApiProviderManager>().deleteApiKey(apiKey.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除 API 密钥失败')),
        );
      }
    }
  }

  void _toggleApiKeyActive(apiKey) async {
    final updatedKey = apiKey.copyWith(isActive: !apiKey.isActive);
    final success = await context.read<providers.ApiProviderManager>().updateApiKey(updatedKey);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新 API 密钥失败')),
      );
    }
  }

  void _showProviderDetails(provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderDetailScreen(provider: provider),
      ),
    );
  }

  void _editProvider(provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProviderScreen(provider: provider),
      ),
    );
  }

  void _deleteProvider(provider) async {
    final keyCount = context.read<providers.ApiProviderManager>().getApiKeysForProvider(provider.id).length;
    
    if (keyCount > 0) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('无法删除供应商'),
          content: Text('此供应商有 $keyCount 个 API 密钥。请先删除所有 API 密钥。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除供应商'),
        content: Text('确定要删除 "${provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<providers.ApiProviderManager>().deleteProvider(provider.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除供应商失败')),
        );
      }
    }
  }
}