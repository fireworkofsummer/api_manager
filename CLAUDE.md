# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

API Manager is a Flutter application for managing AI provider API keys across devices with WebDAV synchronization. The app supports Android and Windows platforms, allowing users to:

- Store and organize API keys from multiple AI providers (OpenAI, Anthropic, Google AI, Cohere, etc.)
- Add custom providers with configurable base URLs
- Sync data across devices using WebDAV
- Manage API key aliases and descriptions

## Development Commands

### Core Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app (add `-d windows` for Windows, `-d android` for Android)
- `flutter build windows` - Build Windows desktop app
- `flutter build apk` - Build Android APK
- `flutter clean` - Clean build artifacts

### Testing & Quality
- `flutter test` - Run unit tests
- `flutter analyze` - Static analysis
- `dart format .` - Format code
- `flutter pub deps` - Show dependency tree

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
- Uses Provider package for state management
- Main provider: `ApiProvider` in `lib/providers/api_provider.dart`
- Database operations are handled through singleton `DatabaseService`

### Key Dependencies
- `sqflite`: Local SQLite database
- `webdav_client`: WebDAV synchronization
- `provider`: State management
- `uuid`: Unique ID generation
- `crypto`: Encryption utilities

## Database Schema

The app uses SQLite with the following key tables:
- **providers**: Stores AI provider information (name, baseUrl, custom providers)
- **api_keys**: Stores API keys with foreign key to providers
- **sync_config**: WebDAV configuration for synchronization

Default providers (OpenAI, Anthropic, Google AI, Cohere) are automatically inserted on first run.

## Synchronization

WebDAV sync implementation in `SyncService`:
- Conflict resolution based on `updatedAt` timestamps
- Data merging for concurrent modifications
- JSON format for data exchange between devices
- File stored as `api_manager_data.json` on WebDAV server