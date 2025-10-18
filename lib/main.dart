import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/network/http_overrides.dart';
import 'package:projectbrain/core/routing/app_router.dart';
import 'package:projectbrain/helpers/theme.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Main entry point for the application
///
/// Environment can be configured using --dart-define:
/// - Development: flutter run --dart-define=ENVIRONMENT=dev
/// - Staging: flutter run --dart-define=ENVIRONMENT=staging
/// - Production: flutter run --dart-define=ENVIRONMENT=production
///
/// Without --dart-define, defaults are:
/// - Debug mode -> dev
/// - Profile mode -> staging
/// - Release mode -> production
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  // Environment is determined automatically or via --dart-define=ENVIRONMENT
  await AppConfig.init();

  // Log current environment
  logInfo('[App] Running in ${AppConfig.environmentName} environment');

  // Initialize HTTP overrides for local development
  initializeHttpOverrides();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize auth provider
  await sl<AuthProvider>().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create router using dependency injection
    final router = sl<AppRouter>().createRouter();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: sl<AuthProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<ChatProvider>(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Project Brain',
        routerConfig: router,
        themeMode: ThemeMode.system,
        theme: getTheme(),
        darkTheme: getDarkTheme(),
      ),
    );
  }
}
