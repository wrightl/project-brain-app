import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/network/http_overrides.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/services/connectivity_service.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/my_app.dart';
import 'package:projectbrain/widgets/app_loading_screen.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Runs the same initialization sequence previously in [main], after the first frame.
Future<void> runApplicationBootstrap() async {
  final startupWatch = Stopwatch()..start();
  logInfo('[Startup] Bootstrap started');

  await _runTimedStep('firebase.init', () async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }, continueOnError: true);

  await _runTimedStep('httpOverrides.init', () async {
    initializeHttpOverrides();
  }, continueOnError: false);

  await _runTimedStep(
    'dependencies.init',
    initializeDependencies,
    continueOnError: false,
  );
  await _runTimedStep(
    'authProvider.init',
    () => sl<AuthProvider>().init(),
    continueOnError: false,
  );

  final authProvider = sl<AuthProvider>();
  logInfo(
      '[Startup] Critical bootstrap complete in ${startupWatch.elapsedMilliseconds}ms (isLoggedIn=${authProvider.isLoggedIn})');

  unawaited(_runDeferredBootstrap(isLoggedIn: authProvider.isLoggedIn));
}

Future<void> _runDeferredBootstrap({required bool isLoggedIn}) async {
  final deferredWatch = Stopwatch()..start();
  logInfo('[Startup] Deferred bootstrap started');

  final tasks = <Future<void>>[
    _runDeferredTask('errorReporting.init', () async {
      await sl<ErrorReportingService>().init();
    }),
    _runDeferredTask('featureFlags.init', () async {
      await sl<FeatureFlagService>().init();
    }),
    _runDeferredTask('connectivity.init', () async {
      await sl<ConnectivityService>().init();
    }),
    _runDeferredTask('push.init', () async {
      await sl<PushNotificationService>().init(requestPermissionsOnInit: false);
    }),
    _runDeferredTask('subscription.init', () async {
      await sl<SubscriptionProvider>().init(refreshInBackground: true);
    }),
    _runDeferredTask('eggGoals.init', () async {
      await sl<EggGoalsProvider>().init();
    }),
  ];

  if (isLoggedIn) {
    tasks.add(
      _runDeferredTask('push.registerToken', () async {
        await sl<PushNotificationService>().registerToken();
      }),
    );
    tasks.add(
      _runDeferredTask('eggGoals.syncFromAPI', () async {
        await sl<EggGoalsProvider>().syncFromAPI();
      }),
    );
    // Open the goals SSE stream on cold launch (previously only started on
    // app resume, so updates were missed until the first background/resume).
    tasks.add(
      _runDeferredTask('goalsRealtime.start', () async {
        await sl<GoalsRealtimeService>()
            .start(() => sl<EggGoalsProvider>().syncFromAPI());
      }),
    );
  }

  await Future.wait(tasks);
  logInfo(
      '[Startup] Deferred bootstrap complete in ${deferredWatch.elapsedMilliseconds}ms');
}

Future<void> _runTimedStep(
  String name,
  Future<void> Function() action, {
  required bool continueOnError,
}) async {
  final stepWatch = Stopwatch()..start();
  logInfo('[Startup] Step started: $name');
  try {
    await action();
    logInfo(
        '[Startup] Step finished: $name (${stepWatch.elapsedMilliseconds}ms)');
  } catch (e, stackTrace) {
    logError('[Startup] Step failed: $name', e, stackTrace);
    if (!continueOnError) {
      rethrow;
    }
  }
}

Future<void> _runDeferredTask(
  String name,
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  final stepWatch = Stopwatch()..start();
  try {
    await action().timeout(timeout);
    logInfo(
        '[Startup] Deferred task finished: $name (${stepWatch.elapsedMilliseconds}ms)');
  } catch (e, stackTrace) {
    logError('[Startup] Deferred task failed: $name', e, stackTrace);
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
