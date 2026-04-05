import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/network/http_overrides.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/my_app.dart';
import 'package:projectbrain/widgets/app_loading_screen.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Runs the same initialization sequence previously in [main], after the first frame.
Future<void> runApplicationBootstrap() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    logInfo('[App] Firebase initialized');
  } catch (e, stackTrace) {
    logError('[App] Error initializing Firebase', e, stackTrace);
  }

  initializeHttpOverrides();

  await initializeDependencies();

  try {
    await sl<ErrorReportingService>().init();
    logInfo('[App] Error reporting service initialized');
  } catch (e, stackTrace) {
    logError('[App] Error initializing error reporting service', e, stackTrace);
  }

  await sl<FeatureFlagService>().init();

  try {
    await sl<PushNotificationService>().init();
    logInfo('[App] Push notification service initialized');
  } catch (e, stackTrace) {
    logError(
        '[App] Error initializing push notification service', e, stackTrace);
  }

  await sl<AuthProvider>().init();

  final authProvider = sl<AuthProvider>();
  if (authProvider.isLoggedIn) {
    try {
      await sl<PushNotificationService>().registerToken();
    } catch (e, stackTrace) {
      logError('[App] Error registering push token after auth', e, stackTrace);
    }
  }

  await sl<SubscriptionProvider>().init();

  await sl<EggGoalsProvider>().init();

  if (authProvider.isLoggedIn) {
    sl<EggGoalsProvider>().syncFromAPI();
  }
}

/// Root widget: animated splash while [runApplicationBootstrap] runs, then [MyApp].
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Object? _error;
  bool _bootstrapComplete = false;
  bool _splashExited = false;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    setState(() => _error = null);
    try {
      await runApplicationBootstrap();
      if (!mounted) return;
      setState(() => _bootstrapComplete = true);
    } catch (e, st) {
      logError('[App] Bootstrap failed', e, st);
      if (!mounted) return;
      setState(() {
        _error = e;
        _bootstrapComplete = false;
      });
    }
  }

  void _retry() {
    unawaited(_retryAsync());
  }

  Future<void> _retryAsync() async {
    await resetDependencies();
    if (!mounted) return;
    setState(() {
      _bootstrapComplete = false;
      _splashExited = false;
      _error = null;
    });
    await _startBootstrap();
  }

  void _onExitComplete() {
    if (!mounted) return;
    setState(() => _splashExited = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_splashExited) {
      return const MyApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kSplashAccent),
        useMaterial3: true,
      ),
      home: AppLoadingScreen(
        bootstrapComplete: _bootstrapComplete,
        error: _error,
        onRetry: _error != null ? _retry : null,
        onExitComplete: _onExitComplete,
      ),
    );
  }
}
