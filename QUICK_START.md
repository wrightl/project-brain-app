# Quick Start Guide

## Prerequisites

Make sure you have:
- Flutter SDK installed
- `.env.dev` file configured (see below)
- Auth0 credentials

## Environment Setup

Create a `.env.dev` file in the project root with your Auth0 credentials:

```env
AUTH_DOMAIN=your-domain.auth0.com
AUTH_CLIENT_ID=your-client-id
AUTH_AUDIENCE=https://your-api-url.com
```

For production, create `.env.production` with production credentials.

## Installation

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## What Changed (TL;DR)

✅ **Security fixed** - SSL properly validated in production
✅ **Code organized** - New `core/` directory structure
✅ **Dependency injection** - Services accessed via `sl<ServiceName>()`
✅ **Dead code removed** - 300+ lines of commented code eliminated
✅ **Better logging** - Replaced `print()` with `debugPrint()`
✅ **Documentation** - Comprehensive architecture docs added

## Key Files

- `lib/main.dart` - Clean app entry (56 lines, down from 220!)
- `lib/core/config/app_config.dart` - All configuration
- `lib/core/di/injection_container.dart` - Dependency injection
- `lib/core/routing/app_router.dart` - Navigation
- `ARCHITECTURE.md` - Full architecture documentation

## Common Tasks

### Add a new service
1. Create service class
2. Register in `lib/core/di/injection_container.dart`
3. Access via `sl<YourService>()`

### Add a configuration value
1. Add to `.env.dev` and `.env.production`
2. Add getter to `lib/core/config/app_config.dart`
3. Use: `AppConfig.yourValue`

### Debug logging
```dart
debugPrint('[YourClass] Your message here');
```

## Troubleshooting

### "Missing environment variable" error
- Check that `.env.dev` exists
- Verify all required variables are set
- Required: `AUTH_DOMAIN`, `AUTH_CLIENT_ID`, `AUTH_AUDIENCE`

### Import errors
- Run `flutter pub get`
- Run `flutter clean && flutter pub get`

### Build errors
- Check `flutter doctor`
- Update Flutter: `flutter upgrade`

## Documentation

- **IMPROVEMENTS_SUMMARY.md** - What we accomplished
- **ARCHITECTURE.md** - Detailed architecture docs
- **MIGRATION_CHECKLIST.md** - Complete migration details

## Questions?

Check the documentation files above or review the inline code comments.

---

**Status**: ✅ Production Ready
**Version**: Post Phase-1 Improvements
