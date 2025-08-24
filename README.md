# API Manager - AI API密钥管理器

<div align="center">
  <h3>轻量级、跨平台的AI供应商API密钥管理工具</h3>
  <p>支持Android移动端和Windows桌面端，通过WebDAV实现多设备同步</p>
</div>

## ✨ 功能特性

### 🔐 安全的密钥管理
- **多供应商支持**：管理OpenAI、Claude、Google Gemini等AI供应商的API密钥
- **自定义供应商**：添加自定义AI供应商和API地址
- **密钥保护**：本地加密存储，支持密钥别名和备注
- **批量管理**：一个供应商可添加多个API密钥

### 🌐 跨设备同步
- **WebDAV同步**：通过WebDAV协议实现多设备数据同步
- **自动备份**：定期自动备份，防止数据丢失
- **冲突解决**：智能处理同步冲突，保证数据一致性

### 📱 跨平台支持
- **Android移动端**：随时随地管理API密钥
- **Windows桌面端**：完整的桌面体验
- **统一界面**：Material Design 3设计语言

### 🎨 现代化界面
- **简洁美观**：符合现代审美的界面设计
- **暗色主题**：支持明暗主题自动切换
- **流畅动画**：丰富的交互动画效果
- **响应式布局**：适配不同屏幕尺寸

## 🚀 快速开始

### 环境要求
- Flutter 3.8.1 或更高版本
- Android SDK（移动端）
- Visual Studio 2022（Windows桌面端）

### 安装依赖
```bash
cd api_manager
flutter pub get
```

### 运行应用

**Windows桌面版：**
```bash
flutter run -d windows
```

**Android版：**
```bash
flutter run -d android
```

### 构建发布版本

**Windows可执行文件：**
```bash
flutter build windows --release
# 输出位置: build\windows\x64\runner\Release\api_manager.exe
```

**Android APK：**
```bash
flutter build apk --release
# 输出位置: build/app/outputs/flutter-apk/app-release.apk
```

## 📖 使用指南

### 1. 添加API供应商
- 点击"添加供应商"按钮
- 输入供应商名称和API基础URL
- 保存后即可开始添加API密钥

### 2. 管理API密钥
- 选择对应的供应商
- 点击"添加密钥"
- 输入API密钥、别名和备注信息
- 支持启用/禁用密钥状态

### 3. 配置WebDAV同步
- 进入同步设置页面
- 配置WebDAV服务器信息
- 设置自动同步间隔
- 手动触发同步或查看同步状态

### 4. 密钥安全
- 所有密钥均采用本地加密存储
- 显示时自动脱敏（如：sk-1234...5678）
- 支持复制完整密钥到剪贴板

## 🛠️ 技术架构

### 核心技术栈
- **框架**：Flutter 3.8.1
- **状态管理**：Provider
- **本地存储**：SQLite + SharedPreferences
- **网络请求**：Dio + HTTP
- **同步协议**：WebDAV
- **加密**：Dart Crypto

### 项目结构
```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── api_key.dart         # API密钥模型
│   ├── api_provider.dart    # 供应商模型
│   └── sync_config.dart     # 同步配置模型
├── providers/               # 状态管理
│   └── api_provider.dart    # 主要状态管理器
├── screens/                 # 界面页面
│   ├── home_screen.dart     # 主页面
│   ├── add_api_key_screen.dart    # 添加密钥页面
│   ├── add_provider_screen.dart   # 添加供应商页面
│   └── sync_settings_screen.dart  # 同步设置页面
├── services/                # 业务服务
│   ├── database_service.dart      # 数据库服务
│   └── sync_service.dart          # 同步服务
├── utils/                   # 工具类
│   └── app_theme.dart       # 主题配置
└── widgets/                 # 通用组件
    ├── api_key_card.dart    # 密钥卡片组件
    ├── provider_card.dart   # 供应商卡片组件
    └── sync_status_widget.dart     # 同步状态组件
```

## 🔧 开发配置

### 调试模式
```bash
flutter run --debug
```

### 性能分析
```bash
flutter run --profile
```

### 代码检查
```bash
flutter analyze
flutter test
```

## 📝 更新日志

### v1.0.0 (当前版本)
- ✅ 基础API密钥管理功能
- ✅ 自定义供应商支持
- ✅ WebDAV同步功能
- ✅ Android和Windows平台支持
- ✅ Material Design 3界面

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进这个项目！

### 开发流程
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详情请见 [LICENSE](LICENSE) 文件。

## 🆘 支持与反馈

如果遇到问题或有功能建议，请：
- 创建 [Issue](https://github.com/yourusername/api_manager/issues)
- 发送邮件至：fireworkofsummer@gmail.com

---

<div align="center">
  <p>用 ❤️ 和 Flutter 构建</p>
</div>
