import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/api_provider.dart';

class AddProviderScreen extends StatefulWidget {
  final ApiProvider? provider;

  const AddProviderScreen({super.key, this.provider});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _iconUrlController = TextEditingController();

  bool _isLoading = false;

  bool get _isEditing => widget.provider != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.provider!.name;
      _baseUrlController.text = widget.provider!.baseUrl;
      _iconUrlController.text = widget.provider!.iconUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑供应商' : '添加供应商'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProvider,
            child: Text(_isEditing ? '更新' : '保存'),
          ),
        ],
      ),
      body: Form(
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
                      '供应商信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '供应商名称 *',
                        hintText: '例如：OpenAI、Anthropic',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入供应商名称';
                        }
                        if (value.trim().length < 2) {
                          return '供应商名称太短';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: '基础 URL *',
                        hintText: 'https://api.example.com/v1',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入基础 URL';
                        }

                        final uri = Uri.tryParse(value.trim());
                        if (uri == null ||
                            !uri.hasScheme ||
                            !uri.hasAuthority) {
                          return '请输入有效的 URL';
                        }

                        if (!['http', 'https'].contains(uri.scheme)) {
                          return 'URL 必须使用 http 或 https';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _iconUrlController,
                      decoration: const InputDecoration(
                        labelText: '图标 URL（可选）',
                        hintText: 'https://example.com/icon.png',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.hasScheme ||
                              !uri.hasAuthority) {
                            return '请输入有效的 URL';
                          }

                          if (!['http', 'https'].contains(uri.scheme)) {
                            return 'URL 必须使用 http 或 https';
                          }
                        }
                        return null;
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
                      '常用供应商',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '快速设置流行 AI 供应商',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getCommonProviders().map((provider) {
                        return ActionChip(
                          label: Text(provider['name']),
                          avatar: Icon(
                            provider['icon'],
                            size: 16,
                            color: provider['color'],
                          ),
                          onPressed: () => _fillProviderTemplate(provider),
                        );
                      }).toList(),
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
                      onPressed: _saveProvider,
                      child: Text(_isEditing ? '更新' : '保存'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCommonProviders() {
    return [
      {
        'name': 'OpenAI',
        'baseUrl': 'https://api.openai.com/v1',
        'icon': Icons.smart_toy,
        'color': const Color(0xFF00A67E),
      },
      {
        'name': 'Anthropic',
        'baseUrl': 'https://api.anthropic.com/v1',
        'icon': Icons.psychology,
        'color': const Color(0xFFD97706),
      },
      {
        'name': 'Google AI',
        'baseUrl': 'https://generativelanguage.googleapis.com/v1',
        'icon': Icons.assistant,
        'color': const Color(0xFF4285F4),
      },
      {
        'name': 'Cohere',
        'baseUrl': 'https://api.cohere.ai/v1',
        'icon': Icons.chat,
        'color': const Color(0xFF39C5BB),
      },
      {
        'name': 'Hugging Face',
        'baseUrl': 'https://api-inference.huggingface.co',
        'icon': Icons.face,
        'color': const Color(0xFFFFD21E),
      },
      {
        'name': 'Azure OpenAI',
        'baseUrl':
            'https://YOUR_RESOURCE.openai.azure.com/openai/deployments/YOUR_DEPLOYMENT',
        'icon': Icons.cloud,
        'color': const Color(0xFF0078D4),
      },
      {
        'name': 'Ollama',
        'baseUrl': 'http://localhost:11434/v1',
        'icon': Icons.computer,
        'color': const Color(0xFF000000),
      },
    ];
  }

  void _fillProviderTemplate(Map<String, dynamic> template) {
    setState(() {
      _nameController.text = template['name'];
      _baseUrlController.text = template['baseUrl'];
      _iconUrlController.clear();
    });
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = ApiProvider(
        id: _isEditing ? widget.provider!.id : '',
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        iconUrl: _iconUrlController.text.trim().isEmpty
            ? null
            : _iconUrlController.text.trim(),
        isCustom: true,
        createdAt: _isEditing ? widget.provider!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await context.read<ApiProviderManager>().updateProvider(
          provider,
        );
      } else {
        final existingProviders = context.read<ApiProviderManager>().providers;
        final nameExists = existingProviders.any(
          (p) =>
              p.name.toLowerCase() == provider.name.toLowerCase() &&
              p.id != provider.id,
        );

        if (nameExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('此名称的供应商已存在'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        success = await context.read<ApiProviderManager>().addProvider(
          provider,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '供应商更新成功' : '供应商添加成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '更新供应商失败' : '添加供应商失败'),
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
}
