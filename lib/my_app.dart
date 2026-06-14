import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/routing/app_router.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/services/connectivity_service.dart';
import 'package:projectbrain/widgets/offline_banner.dart';
import 'package:projectbrain/helpers/theme_mode_provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Build the router once; createRouter() is idempotent but holding the
  // instance keeps build() free of side effects.
  late final _router = sl<AppRouter>().createRouter();

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
    if (state == AppLifecycleState.resumed) {
      sl<EggGoalsProvider>().syncFromAPI();
      if (sl<AuthProvider>().isLoggedIn) {
        sl<GoalsRealtimeService>()
            .start(() => sl<EggGoalsProvider>().syncFromAPI());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      sl<GoalsRealtimeService>().stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: sl<AuthProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<ThemeModeProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<ChatProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<SubscriptionProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<EggGoalsProvider>(),
        ),
        ChangeNotifierProvider.value(
          value: sl<JournalProvider>(),
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
        ChangeNotifierProvider<ConnectivityService>.value(
          value: sl<ConnectivityService>(),
        ),
      ],
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeModeProvider, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Project Brain',
            routerConfig: router,
            themeMode: themeModeProvider.themeMode,
            theme: themeModeProvider.theme,
            darkTheme: themeModeProvider.darkTheme,
            // Overlay a persistent offline banner above every route.
            builder: (context, child) => OfflineBanner(child: child),
          );
        },
      ),
    );
  }
}
