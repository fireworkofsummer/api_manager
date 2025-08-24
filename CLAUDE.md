# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

API Manager is a Flutter application for managing AI provider API keys across devices with WebDAV synchronization. The app supports Android and Windows platforms, allowing users to:

- Store and organize API keys from multiple AI providers (OpenAI, Anthropic, Google AI, Cohere, etc.)
- Add custom providers with configurable base URLs
- Sync data across devices using WebDAV
- Manage API key aliases and descriptions
- **Automatic in-app updates with data preservation**

## Development Requirements

- Flutter 3.8.1 or higher (current SDK: ^3.8.1)
- Android SDK (for mobile development)
- Visual Studio 2022 (for Windows desktop development)
- Dart SDK compatible with Flutter version

## Development Commands

### Core Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app (add `-d windows` for Windows, `-d android` for Android)
- `flutter build windows --release` - Build Windows desktop app (outputs to build\windows\x64\runner\Release\)
- `flutter build apk --release` - Build Android APK (outputs to build/app/outputs/flutter-apk/)
- `flutter clean` - Clean build artifacts

### Testing & Quality
- `flutter test` - Run unit tests
- `flutter analyze` - Static analysis using flutter_lints rules
- `dart format .` - Format code according to Dart style guide
- `flutter pub deps` - Show dependency tree
- `flutter run --debug` - Run in debug mode
- `flutter run --profile` - Run in profile mode for performance analysis

### Platform-Specific Development
- `flutter run -d windows` - Run on Windows
- `flutter run -d android` - Run on Android emulator/device
- `flutter devices` - List available devices

## Architecture

### Core Structure
- **Models** (`lib/models/`): Data classes for ApiProvider, ApiKey, and SyncConfig
- **Services** (`lib/services/`): DatabaseService (SQLite) and SyncService (WebDAV)
- **Providers** (`lib/providers/`): State management using Provider package
- **Screens** (`lib/screens/`): UI screens for different app functionalities
- **Widgets** (`lib/widgets/`): Reusable UI components
- **Utils** (`lib/utils/`): App theming and utilities

### Data Layer
- **Local Storage**: SQLite database with three main tables:
  - `providers`: AI service providers (OpenAI, Anthropic, etc.)
  - `api_keys`: API keys with metadata (alias, description, last used)
  - `sync_config`: WebDAV synchronization settings
- **Sync**: WebDAV client for cross-device synchronization with conflict resolution

### State Management
- Uses Provider package with ChangeNotifier pattern
- Main state manager: `ApiProviderManager` in `lib/providers/api_provider.dart`
- Database operations handled through singleton `DatabaseService`
- State includes loading states, error handling, and reactive UI updates
- Provider initialized in main.dart and consumed throughout the app hierarchy

### Key Dependencies
- `sqflite`: Local SQLite database storage
- `webdav_client`: WebDAV synchronization protocol
- `provider`: State management (ChangeNotifier pattern)
- `uuid`: Unique ID generation for database records
- `crypto`: Encryption utilities for secure storage
- `dio` & `http`: HTTP client libraries
- `shared_preferences`: Simple key-value storage
- `flutter_staggered_animations` & `animations`: UI animations
- `flutter_lints`: Static analysis rules
- `package_info_plus`: App version information for updates
- `url_launcher`: Opening URLs and launching external apps
- `permission_handler`: Managing Android permissions for updates

## Database Schema

The app uses SQLite database (`api_manager.db`) with four main tables:
- **providers**: Stores AI provider information (id, name, baseUrl, iconUrl, isCustom, timestamps)
- **api_keys**: Stores API keys with metadata (id, providerId, keyValue, alias, description, isEnabled, timestamps)
- **sync_config**: WebDAV configuration for synchronization (url, username, password, autoSync settings)
- **app_settings**: Application settings including version info and update preferences (appVersion, buildNumber, lastUpdateCheck, autoCheckUpdates, downloadUpdatesOnWifi)

Default providers (OpenAI, Anthropic, Google AI, Cohere, etc.) are automatically inserted on first run. Database uses singleton pattern through `DatabaseService` with automatic schema migration from version 1 to 2.

## Synchronization

WebDAV sync implementation in `SyncService`:
- Conflict resolution based on `updatedAt` timestamps
- Data merging for concurrent modifications
- JSON format for data exchange between devices
- File stored as `api_manager_data.json` on WebDAV server

## In-App Update System

The app includes a comprehensive update system that preserves user data:

### Update Architecture
- **UpdateService** (`lib/services/update_service.dart`): Handles version checking, downloading, and installation
- **AppVersion** model (`lib/models/app_version.dart`): Version data structure with release information
- **UpdateDialog** widget (`lib/widgets/update_dialog.dart`): User interface for update notifications
- **SettingsScreen** (`lib/screens/settings_screen.dart`): Update preferences and manual check

### Update Flow
1. **Automatic Check**: On app startup, checks GitHub releases API for new versions (if enabled)
2. **Version Comparison**: Compares current version with latest using semantic versioning
3. **User Notification**: Shows update dialog with release notes and download options
4. **Download & Install**: 
   - Android: Downloads APK and triggers installation intent
   - Windows: Opens browser to download page for manual installation
5. **Data Preservation**: Database migration ensures all user data is preserved across updates

### Update Settings
- Auto-check updates on startup (configurable)
- WiFi-only downloads to save mobile data
- Manual update check from settings
- Last update check timestamp tracking

### GitHub Integration
- Expects releases with semantic versioning (e.g., v1.0.0)
- Supports platform-specific assets (APK for Android, ZIP for Windows)
- Parses release notes for update information
- Supports force update flag with `[force-update]` in release notes

### Required Permissions (Android)
- `INTERNET` & `ACCESS_NETWORK_STATE`: Network access for update checks
- `WRITE_EXTERNAL_STORAGE` & `READ_EXTERNAL_STORAGE`: Download APK files
- `REQUEST_INSTALL_PACKAGES`: Install downloaded APK
- FileProvider configuration for secure APK sharing