# Project Brain

A Flutter application developed by Dot+Dash Consulting, featuring AI-powered chat, resource management, voice notes, quizzes, coaching network, and subscription management.

## Table of Contents

-   [Technology Stack](#technology-stack)
-   [Architecture](#architecture)
-   [Project Structure](#project-structure)
-   [Prerequisites](#prerequisites)
-   [Development Environment Setup](#development-environment-setup)
-   [Configuration](#configuration)
-   [Running the Application](#running-the-application)
-   [Building for Production](#building-for-production)
-   [iOS: Build and distribute](#ios-build-and-distribute)
-   [Testing](#testing)
-   [Code Generation](#code-generation)
-   [Best Practices](#best-practices)
-   [Troubleshooting](#troubleshooting)

## Technology Stack

### Core Framework

-   **Flutter**: ^3.6.1 (Dart SDK)
-   **Dart**: ^3.6.1

### State Management

-   **Provider**: ^6.1.2 - State management for UI
-   **flutter_bloc**: ^9.1.1 - BLoC pattern implementation
-   **bloc**: ^9.1.0 - Core BLoC library

### Dependency Injection

-   **get_it**: ^9.0.5 - Service locator for dependency injection
-   **injectable**: ^2.5.0 - Code generation for dependency injection

### Routing & Navigation

-   **go_router**: ^17.0.0 - Declarative routing solution

### Authentication & Security

-   **auth0_flutter**: ^1.9.0 - Auth0 authentication
-   **flutter_appauth**: ^11.0.0 - OAuth 2.0 and OpenID Connect
-   **flutter_secure_storage**: ^9.2.2 - Secure key-value storage

### Networking & API

-   **http**: ^1.3.0 - HTTP client
-   **dartz**: ^0.10.1 - Functional programming utilities (Either, Option)

### Data Persistence

-   **shared_preferences**: ^2.5.3 - Simple key-value storage
-   **hive**: ^2.2.3 - Lightweight NoSQL database
-   **hive_flutter**: ^1.1.0 - Hive Flutter integration

### Code Generation

-   **freezed**: ^3.2.3 - Code generation for immutable classes
-   **json_serializable**: ^6.9.2 - JSON serialization
-   **json_annotation**: ^4.9.0 - JSON annotations
-   **freezed_annotation**: ^3.1.0 - Freezed annotations
-   **build_runner**: ^2.4.13 - Code generation runner

### UI & UX

-   **flutter_markdown**: ^0.7.7+1 - Markdown rendering
-   **cached_network_image**: ^3.3.1 - Image caching
-   **confetti**: ^0.8.0 - Confetti animations
-   **webview_flutter**: ^4.9.0 - WebView integration

### Media & Files

-   **image_picker**: ^1.1.2 - Image selection
-   **file_picker**: ^8.1.4 - File selection
-   **record**: ^6.1.2 - Audio recording
-   **just_audio**: ^0.9.40 - Audio playback
-   **path_provider**: ^2.1.4 - File system paths

### Analytics & Monitoring

-   **firebase_core**: ^4.2.0 - Firebase initialization
-   **firebase_analytics**: ^12.0.3 - Analytics tracking
-   **firebase_crashlytics**: ^5.0.3 - Crash reporting
-   **opentelemetry**: ^0.18.6 - Observability

### Feature Flags

-   **launchdarkly_flutter_client_sdk**: ^4.14.0 - Feature flag management

### Utilities

-   **flutter_dotenv**: ^6.0.0 - Environment variable management
-   **connectivity_plus**: ^7.0.0 - Network connectivity
-   **url_launcher**: ^6.3.1 - URL launching
-   **intl**: ^0.19.0 - Internationalization
-   **logger**: ^2.5.0 - Logging
-   **equatable**: ^2.0.7 - Value equality

### Testing

-   **flutter_test**: SDK - Unit and widget testing
-   **integration_test**: SDK - Integration testing
-   **mocktail**: ^1.0.4 - Mocking framework
-   **test**: ^1.16.0 - Testing framework

## Architecture

### Design Patterns

#### 1. **Dependency Injection (DI)**

-   Uses `get_it` as the service locator
-   All services are registered in `lib/core/di/injection_container.dart`
-   Services are injected via constructor injection
-   Supports lazy initialization and singletons

#### 2. **Provider Pattern**

-   State management using `Provider` package
-   Providers manage UI state and business logic
-   Key providers:
    -   `AuthProvider` - Authentication state
    -   `ChatProvider` - Chat functionality
    -   `SubscriptionProvider` - Subscription management

#### 3. **Service Layer Pattern**

-   Business logic separated into service classes
-   Services handle API calls, data processing, and business rules
-   Services are registered in the DI container

#### 4. **Repository Pattern** (Implicit)

-   Services act as repositories, abstracting data sources
-   Clear separation between data access and business logic

#### 5. **BLoC Pattern** (Partial)

-   Some features use BLoC for state management
-   Can be extended for complex state management needs

### Architecture Layers

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Pages, Widgets, Providers)        │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│          Service Layer               │
│  (Business Logic, API Calls)        │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│          Data Layer                  │
│  (Models, Storage, Network)         │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│         Core Layer                   │
│  (DI, Config, Routing, Logging)     │
└─────────────────────────────────────┘
```

### Key Architectural Decisions

1. **Environment-Based Configuration**: Uses `.env` files for different environments (dev, staging, production)
2. **Centralized Routing**: All routes defined in `AppRouter` with authentication guards
3. **Secure Token Storage**: Tokens stored using `flutter_secure_storage`
4. **Feature Flags**: LaunchDarkly integration for feature toggling
5. **Error Handling**: Centralized error handling with proper logging
6. **Offline Support**: Hive for local caching and offline capabilities

## Project Structure

```
lib/
├── authentication/          # Authentication UI and logic
│   ├── auth_provider.dart   # Auth state management
│   └── login_page.dart      # Login UI
│
├── chat/                    # Chat functionality
│   ├── chat_page.dart       # Chat UI
│   └── chat_provider.dart   # Chat state management
│
├── core/                    # Core functionality
│   ├── config/              # App configuration
│   │   └── app_config.dart  # Environment & config management
│   ├── di/                  # Dependency injection
│   │   └── injection_container.dart
│   ├── errors/              # Error handling
│   ├── logging/             # Logging utilities
│   ├── network/             # Network configuration
│   ├── routing/             # Navigation
│   │   └── app_router.dart  # Route definitions
│   ├── storage/             # Storage services
│   └── usecases/            # Use cases (if any)
│
├── helpers/                 # Helper utilities
│   └── theme.dart           # Theme configuration
│
├── home/                    # Home screen
│   └── home_page.dart
│
├── models/                  # Data models
│   ├── *.dart               # Model definitions
│   ├── *.freezed.dart       # Generated Freezed code
│   └── *.g.dart             # Generated JSON serialization
│
├── network/                 # Network/coaching features
│
├── onboarding/             # Onboarding flow
│   └── onboarding_page.dart
│
├── resources/               # Resources management
│
├── services/                # Business logic services
│   ├── auth/                # Authentication services
│   │   ├── auth_service.dart
│   │   ├── oauth_service.dart
│   │   ├── token_manager.dart
│   │   ├── token_storage.dart
│   │   └── user_profile_service.dart
│   ├── ai_service.dart      # AI/chat service
│   ├── coach_service.dart   # Coach management
│   ├── conversation_service.dart
│   ├── feature_flag_service.dart
│   ├── quiz_service.dart
│   ├── resource_service.dart
│   ├── subscription_service.dart
│   └── voice_note_service.dart
│
├── subscription/            # Subscription management
│
├── user/                    # User profile & settings
│
├── utils/                   # Utility functions
│
├── voicenotes/              # Voice notes feature
│
├── widgets/                 # Reusable widgets
│   ├── chat/                # Chat-specific widgets
│   └── custom_bottom_nav_bar.dart
│
└── main.dart                # Application entry point

test/                        # Unit and widget tests
├── authentication/
├── helpers/
├── services/
└── widgets/

integration_test/            # Integration tests
├── auth_flow_test.dart
└── chat_flow_test.dart
```

## Prerequisites

Before setting up the development environment, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.6.1 or compatible)

    - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
    - Verify installation: `flutter doctor`

2. **Dart SDK** (3.6.1 or compatible)

    - Included with Flutter installation

3. **IDE** (choose one)

    - **VS Code** with Flutter extension (recommended)
    - **Android Studio** with Flutter plugin
    - **IntelliJ IDEA** with Flutter plugin

4. **Platform-Specific Requirements**

    **For iOS Development:**

    - macOS (required)
    - Xcode (latest stable version)
    - CocoaPods: `sudo gem install cocoapods`
    - iOS Simulator or physical device

    **For Android Development:**

    - Android Studio
    - Android SDK (API level 21+)
    - Android Emulator or physical device
    - Java Development Kit (JDK) 11 or later

### Required Accounts & Services

1. **Auth0 Account**

    - Auth0 domain
    - Client ID
    - Audience/API identifier

2. **LaunchDarkly Account**

    - Client-side ID
    - Mobile key

3. **Firebase Project** (for analytics and crash reporting)
    - Firebase project configuration
    - `google-services.json` (Android)
    - `GoogleService-Info.plist` (iOS)

## Development Environment Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd projectbrain
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Install Platform-Specific Dependencies

**iOS:**

```bash
cd ios
pod install
cd ..
```

**Android:**

-   Android dependencies are managed via Gradle and will be installed automatically

### 4. Configure Environment Variables

Create environment configuration files in the project root:

**`.env.dev`** (Development):

```env
AUTH_DOMAIN=your-auth0-domain.auth0.com
AUTH_CLIENT_ID=your-dev-client-id
AUTH_AUDIENCE=http://localhost:3000/api
LAUNCHDARKLY_CLIENT_SIDE_ID=your-ld-client-id
LAUNCHDARKLY_MOBILE_KEY=your-ld-mobile-key
```

**`.env.staging`** (Staging):

```env
AUTH_DOMAIN=your-auth0-domain.auth0.com
AUTH_CLIENT_ID=your-staging-client-id
AUTH_AUDIENCE=https://staging-api.example.com
LAUNCHDARKLY_CLIENT_SIDE_ID=your-ld-client-id
LAUNCHDARKLY_MOBILE_KEY=your-ld-mobile-key
```

**`.env.production`** (Production):

```env
AUTH_DOMAIN=your-auth0-domain.auth0.com
AUTH_CLIENT_ID=your-prod-client-id
AUTH_AUDIENCE=https://api.example.com
LAUNCHDARKLY_CLIENT_SIDE_ID=your-ld-client-id
LAUNCHDARKLY_MOBILE_KEY=your-ld-mobile-key
```

> **Note**: These files are typically not committed to version control. Add them to `.gitignore` and use a secure method to share credentials with team members.

### 5. Configure Firebase

**Android:**

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`

**iOS:**

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Add it to the Xcode project

### 6. Generate Code

Run code generation for models and dependency injection:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:

-   Freezed model files (`*.freezed.dart`)
-   JSON serialization files (`*.g.dart`)
-   Injectable dependency injection code

### 7. Verify Setup

Run Flutter doctor to check for any issues:

```bash
flutter doctor -v
```

## Configuration

### Environment Selection

The app supports three environments: `dev`, `staging`, and `production`.

**Method 1: Using Dart Defines (Recommended)**

```bash
# Development
flutter run --dart-define=ENVIRONMENT=dev

# Staging
flutter run --dart-define=ENVIRONMENT=staging

# Production
flutter run --dart-define=ENVIRONMENT=production
```

**Method 2: Automatic Detection**

-   **Debug mode** → `dev` environment
-   **Profile mode** → `staging` environment
-   **Release mode** → `production` environment

### App Configuration

Configuration is managed in `lib/core/config/app_config.dart`:

-   **Auth0 Settings**: Domain, Client ID, Audience
-   **LaunchDarkly Settings**: Client-side ID, Mobile Key
-   **API Base URL**: Derived from Auth0 audience
-   **Bundle Identifier**: `com.dotdash.projectbrain`

### Build Configuration

**iOS:**

-   Bundle ID: `com.dotdash.projectbrain`
-   Minimum iOS version: Check `ios/Podfile`
-   Signing: Configure in Xcode

**Android:**

-   Package name: `com.dotdash.projectbrain`
-   Minimum SDK: Check `android/app/build.gradle`
-   Signing: Configure in `android/app/build.gradle`

## Running the Application

### Development Mode

```bash
# Run on default device (dev environment)
flutter run

# Run with specific environment
flutter run --dart-define=ENVIRONMENT=dev

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>         # Run on specific device

# Run with hot reload enabled (default)
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

### Profile Mode (Performance Testing)

```bash
flutter run --profile --dart-define=ENVIRONMENT=staging
```

### Release Mode

```bash
flutter run --release --dart-define=ENVIRONMENT=production
```

### Platform-Specific Commands

**iOS:**

```bash
# Run on iOS Simulator
flutter run -d ios

# Run on physical iOS device
flutter run -d <device-id>
```

**Android:**

```bash
# Run on Android Emulator
flutter run -d android

# Run on physical Android device
flutter run -d <device-id>
```

## Building for Production

### iOS: Build and distribute

Ensure signing is configured in Xcode first (`open ios/Runner.xcworkspace` → **Runner** target → **Signing & Capabilities**). Copy the appropriate `.env.*.example` to `.env.dev`, `.env.staging`, or `.env.production` before building.

#### Automated build script (recommended)

[`scripts/build_ios.sh`](scripts/build_ios.sh) increments the pubspec build number, builds an IPA for the given environment, and uploads to App Store Connect for **staging** and **production**. **dev** builds locally and skips upload.

```bash
# Staging or production: bump build number, build, upload to TestFlight
export ASC_API_KEY_ID=YOUR_API_KEY_ID
export ASC_API_ISSUER_ID=YOUR_ISSUER_ID
./scripts/build_ios.sh staging
./scripts/build_ios.sh production

# Dev: bump build number and build IPA only (no upload)
./scripts/build_ios.sh dev

# Optional flags
./scripts/build_ios.sh production --obfuscate   # Crashlytics symbol files
./scripts/build_ios.sh staging --no-bump        # skip pubspec increment
./scripts/build_ios.sh production --no-upload   # build IPA only
./scripts/build_ios.sh production --commit      # git commit pubspec.yaml after success
```

| Variable | Purpose |
| --- | --- |
| `ASC_API_KEY_ID` | App Store Connect API Key ID |
| `ASC_API_ISSUER_ID` | Issuer ID from App Store Connect |

Store the downloaded `.p8` key as **`private_keys/AuthKey_<ASC_API_KEY_ID>.p8`** at the project root (gitignored). Create the key under App Store Connect → Users and Access → Keys.

After upload, finish processing and TestFlight/App Store steps in [App Store Connect](https://appstoreconnect.apple.com).

#### Manual steps (alternative)

1. **Update the version** — edit `pubspec.yaml`: `version: x.y.z+build` (`+build` must increase for each Apple upload).

2. **Create the IPA**

    ```bash
    flutter build ipa --dart-define=ENVIRONMENT=production
    ```

    Optional obfuscation (keep symbols off-repo):

    ```bash
    flutter build ipa --dart-define=ENVIRONMENT=production \
      --obfuscate --split-debug-info=build/symbols/ios
    ```

    Output: `build/ios/ipa/*.ipa`.

3. **Upload with App Store Connect API key**

    ```bash
    xcrun altool --upload-app --type ios \
      -f build/ios/ipa/*.ipa \
      --apiKey YOUR_API_KEY_ID \
      --apiIssuer YOUR_ISSUER_ID
    ```

### Android Build

1. **Configure Signing:**

    - Create or use existing keystore
    - Configure in `android/app/build.gradle`

2. **Build APK:**

    ```bash
    flutter build apk --dart-define=ENVIRONMENT=production
    ```

3. **Build App Bundle (for Play Store):**
    ```bash
    flutter build appbundle --dart-define=ENVIRONMENT=production
    ```

### Web Build

```bash
flutter build web --dart-define=ENVIRONMENT=production
```

## Testing

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/authentication/auth_provider_test.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widgets/

# Run specific widget test
flutter test test/widgets/message_bubble_test.dart
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/auth_flow_test.dart
```

### Test Coverage

Generate coverage report:

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (if lcov is installed)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Or use the provided script:

```bash
./scripts/coverage.sh
```

## Code Generation

The project uses code generation for:

-   **Freezed**: Immutable data classes with union types
-   **JSON Serializable**: JSON serialization/deserialization
-   **Injectable**: Dependency injection annotations

### Generate Code

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### When to Regenerate

Regenerate code when you:

-   Add or modify models with `@freezed` or `@JsonSerializable`
-   Add or modify services with `@injectable` annotations
-   Change dependency injection setup

## Best Practices

### Code Style

1. **Follow Dart Style Guide**: The project uses `flutter_lints` package
2. **Run Analysis**: `flutter analyze` before committing
3. **Format Code**: `dart format .` or `flutter format .`

### Architecture Guidelines

1. **Service Layer**: Business logic goes in services, not providers
2. **State Management**: Use Provider for UI state, services for business logic
3. **Dependency Injection**: Always use DI container, avoid direct instantiation
4. **Error Handling**: Use Either pattern from `dartz` for error handling
5. **Logging**: Use `AppLogger` for consistent logging across the app

### File Organization

1. **One Class Per File**: Each class/component in its own file
2. **Naming Conventions**:
    - Files: `snake_case.dart`
    - Classes: `PascalCase`
    - Variables/Functions: `camelCase`
    - Constants: `lowerCamelCase` or `UPPER_SNAKE_CASE`

### Git Workflow

1. **Branch Naming**: `feature/`, `bugfix/`, `hotfix/`, `chore/`
2. **Commit Messages**: Use conventional commits format
3. **Before Committing**:
    ```bash
    flutter analyze
    flutter test
    dart format .
    ```

### Security Best Practices

1. **Never Commit Secrets**: Use `.env` files (already in `.gitignore`)
2. **Secure Storage**: Use `flutter_secure_storage` for sensitive data
3. **Token Management**: Tokens are automatically managed by `TokenManager`
4. **HTTPS Only**: All API calls use HTTPS (except localhost in dev)

### Performance

1. **Image Caching**: Use `cached_network_image` for network images
2. **Lazy Loading**: Use lazy initialization for services
3. **Offline Support**: Leverage Hive for local caching
4. **Profile Mode**: Test performance in profile mode before release

## Troubleshooting

### Common Issues

#### 1. **Code Generation Errors**

**Problem**: `build_runner` fails or generates incorrect code

**Solution**:

```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. **iOS Pod Installation Issues**

**Problem**: CocoaPods errors or missing pods

**Solution**:

```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### 3. **Android Build Errors**

**Problem**: Gradle sync failures or build errors

**Solution**:

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 4. **Environment Variables Not Loading**

**Problem**: App crashes or can't find environment variables

**Solution**:

-   Verify `.env.*` files exist in project root
-   Check file names match: `.env.dev`, `.env.staging`, `.env.production`
-   Ensure files are listed in `pubspec.yaml` assets section
-   Verify environment is set correctly via `--dart-define`

#### 5. **Auth0 Authentication Issues**

**Problem**: Login fails or redirect issues

**Solution**:

-   Verify Auth0 configuration in `.env` files
-   Check redirect URI matches Auth0 dashboard: `com.dotdash.projectbrain://login-callback`
-   Ensure Auth0 application is configured for mobile apps
-   Check network connectivity

#### 6. **Firebase Not Initializing**

**Problem**: Firebase services not working

**Solution**:

-   Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) exists
-   Check Firebase configuration files are in correct locations
-   Ensure Firebase is initialized in `main.dart` (if required)
-   Verify Firebase project settings match app bundle ID

#### 7. **Hot Reload Not Working**

**Problem**: Changes not reflecting during development

**Solution**:

-   Try hot restart: Press `R` in terminal
-   Full restart: Stop app and run `flutter run` again
-   Check for syntax errors: `flutter analyze`

### Getting Help

1. **Check Logs**: Use `AppLogger` output in console
2. **Flutter Doctor**: Run `flutter doctor -v` for environment issues
3. **Flutter Analyze**: Run `flutter analyze` for code issues
4. **Documentation**: Refer to [Flutter Documentation](https://flutter.dev/docs)

## Additional Resources

-   [Flutter Documentation](https://flutter.dev/docs)
-   [Dart Language Tour](https://dart.dev/guides/language/language-tour)
-   [Provider Package](https://pub.dev/packages/provider)
-   [GoRouter Documentation](https://pub.dev/packages/go_router)
-   [Auth0 Flutter SDK](https://pub.dev/packages/auth0_flutter)
-   [Freezed Documentation](https://pub.dev/packages/freezed)
-   [Get It Documentation](https://pub.dev/packages/get_it)

## License

[Add your license information here]

## Contributing

[Add contributing guidelines here]

---

**Last Updated**: [Current Date]
**Flutter Version**: 3.6.1
**Dart Version**: 3.6.1
