import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/api_provider.dart' as providers;

class AddApiKeyScreen extends StatefulWidget {
  final ApiKey? apiKey;
  final String? preSelectedProviderId;

  const AddApiKeyScreen({super.key, this.apiKey, this.preSelectedProviderId});

  @override
  State<AddApiKeyScreen> createState() => _AddApiKeyScreenState();
}

class _AddApiKeyScreenState extends State<AddApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();

  ApiProvider? _selectedProvider;
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscureKey = true;

  bool get _isEditing => widget.apiKey != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _aliasController.text = widget.apiKey!.alias ?? '';
      _keyController.text = widget.apiKey!.keyValue;
      _descriptionController.text = widget.apiKey!.description ?? '';
      _isActive = widget.apiKey!.isActive;
    }

    // Set up the pre-selected provider after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiProvider = context.read<providers.ApiProviderManager>();
      if (_isEditing) {
        _selectedProvider = apiProvider.getProviderById(
          widget.apiKey!.providerId,
        );
      } else if (widget.preSelectedProviderId != null) {
        _selectedProvider = apiProvider.getProviderById(
          widget.preSelectedProviderId!,
        );
      }
      if (mounted && _selectedProvider != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _keyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑 API 密钥' : '添加 API 密钥'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveApiKey,
            child: Text(_isEditing ? '更新' : '保存'),
          ),
        ],
      ),
      body: Consumer<providers.ApiProviderManager>(
        builder: (context, apiProvider, child) {
          if (_isEditing && _selectedProvider == null) {
            _selectedProvider = apiProvider.getProviderById(
              widget.apiKey!.providerId,
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '供应商',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ApiProvider>(
                          value: _selectedProvider,
                          decoration: const InputDecoration(
                            hintText: '选择一个供应商',
                          ),
                          validator: (value) {
                            if (value == null) {
                              return '请选择一个供应商';
                            }
                            return null;
                          },
                          items: apiProvider.providers.map((provider) {
                            return DropdownMenuItem(
                              value: provider,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _getProviderColor(
                                        provider.name,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      _getProviderIcon(provider.name),
                                      size: 16,
                                      color: _getProviderColor(provider.name),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(provider.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isEditing
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedProvider = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API 密钥详情',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _aliasController,
                          decoration: const InputDecoration(
                            labelText: '别名（可选）',
                            hintText: '例如：生产密钥、测试密钥',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _keyController,
                          decoration: InputDecoration(
                            labelText: 'API 密钥',
                            hintText: '输入您的 API 密钥',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureKey
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureKey = !_obscureKey;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureKey,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入 API 密钥';
                            }
                            if (value.trim().length < 10) {
                              return 'API 密钥太短';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: '描述（可选）',
                            hintText: '添加关于此密钥的注释',
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        const SizedBox(height: 16),

                        SwitchListTile(
                          title: const Text('激活'),
                          subtitle: const Text('此密钥是否可用'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveApiKey,
                          child: Text(_isEditing ? '更新' : '保存'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = ApiKey(
        id: _isEditing ? widget.apiKey!.id : '',
        providerId: _selectedProvider!.id,
        keyValue: _keyController.text.trim(),
        alias: _aliasController.text.trim().isEmpty
            ? null
            : _aliasController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
        createdAt: _isEditing ? widget.apiKey!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        lastUsed: _isEditing ? widget.apiKey!.lastUsed : null,
      );

      bool success;
      if (_isEditing) {
        success = await context
            .read<providers.ApiProviderManager>()
            .updateApiKey(apiKey);
      } else {
        success = await context.read<providers.ApiProviderManager>().addApiKey(
          apiKey,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'API 密钥更新成功' : 'API 密钥添加成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '更新 API 密钥失败' : '添加 API 密钥失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('错误: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      default:
        return const Color(0xFF6366F1);
    }
  }
}
