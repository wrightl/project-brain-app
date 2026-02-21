import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/network/http_overrides.dart';
import 'package:projectbrain/core/routing/app_router.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
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

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    logInfo('[App] Firebase initialized');
  } catch (e, stackTrace) {
    logError('[App] Error initializing Firebase', e, stackTrace);
    // Continue even if Firebase initialization fails
  }

  // Initialize HTTP overrides for local development
  initializeHttpOverrides();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize error reporting service (must be early for error tracking)
  try {
    await sl<ErrorReportingService>().init();
    logInfo('[App] Error reporting service initialized');
  } catch (e, stackTrace) {
    logError('[App] Error initializing error reporting service', e, stackTrace);
    // Continue even if error reporting initialization fails
  }

  // Initialize feature flag service
  await sl<FeatureFlagService>().init();

  // Initialize push notification service
  try {
    await sl<PushNotificationService>().init();
    logInfo('[App] Push notification service initialized');
  } catch (e, stackTrace) {
    logError(
        '[App] Error initializing push notification service', e, stackTrace);
    // Continue even if push notification initialization fails
  }

  // Initialize auth provider
  await sl<AuthProvider>().init();

  // Register push notification token if user is authenticated
  final authProvider = sl<AuthProvider>();
  if (authProvider.isLoggedIn) {
    try {
      await sl<PushNotificationService>().registerToken();
    } catch (e, stackTrace) {
      logError('[App] Error registering push token after auth', e, stackTrace);
    }
  }

  // Initialize subscription provider
  await sl<SubscriptionProvider>().init();

  // Initialize egg goals provider
  await sl<EggGoalsProvider>().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Sync goals when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      sl<EggGoalsProvider>().syncFromAPI();
    }
  }

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
        ChangeNotifierProvider.value(
          value: sl<SubscriptionProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<EggGoalsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<JournalProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<StrategiesProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<StrategiesChatProvider>(),
        ),
        Provider<FeatureFlagService>.value(
          value: sl<FeatureFlagService>(),
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
