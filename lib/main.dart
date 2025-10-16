import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:projectbrain/authentication/login_page.dart';
import 'package:projectbrain/authentication/profile_page.dart';
import 'package:projectbrain/chat/chat_page.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/helpers/is_debug.dart';
import 'package:projectbrain/helpers/theme.dart';
import 'package:projectbrain/home/home_page.dart';
import 'package:projectbrain/onboarding/onboarding_page.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';
import 'package:projectbrain/services/log_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  print('Starting app...');
  await dotenv.load(fileName: ".env.dev");

  // Initialize Logger
  final logger = Logger(
    printer: PrettyPrinter(),
    output: LogService(),
  );

  final authProvider = AuthProvider(
    authService: AuthService(),
  );

  if (isInDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // runApp(MaterialApp(
  //   debugShowCheckedModeBanner: false,
  //   title: 'Project Brain',
  //   themeMode: ThemeMode.system,
  //   home: Padding(
  //     padding: const EdgeInsets.all(24.0),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [Center(child: Text('Loading...'))],
  //     ),
  //   ),
  // ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => authProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            aiService: AIService(authService: authProvider.authService),
            conversationService:
                ConversationService(authService: authProvider.authService),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );

  authProvider.init();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class PreferencesManager {
  static final PreferencesManager _instance = PreferencesManager._internal();
  static SharedPreferences? _prefs;

  // Private constructor
  PreferencesManager._internal();

  // Public factory for the singleton instance
  factory PreferencesManager() {
    return _instance;
  }

  // Asynchronously initializes the SharedPreferences instance.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? get lastRoute => _prefs?.getString('last_route_key');

  Future<void> setLastRoute(String route) async {
    print('Persisting last route: $route');
    await _prefs?.setString('last_route_key', route);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _prefsFuture = PreferencesManager.init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        final authProvider = Provider.of<AuthProvider>(context);
        // final lastRoute = PreferencesManager().lastRoute;

        final router = GoRouter(
          refreshListenable: authProvider,
          redirect: (context, state) {
            if (authProvider.isLoading) return null;
            final loggedIn = authProvider.isLoggedIn;
            final onboarded = authProvider.onboardingComplete;
            final loggingIn = state.matchedLocation == '/login';
            final onboarding = state.matchedLocation == '/onboarding';

            if (!loggedIn) return loggingIn ? null : '/login';
            if (loggedIn && !onboarded && !onboarding) return '/onboarding';
            if (loggedIn && onboarded && (loggingIn || onboarding)) return '/';
            return null;
          },
          routes: [
            GoRoute(
                path: '/login', builder: (context, state) => const LoginPage()),
            GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingPage()),
            ShellRoute(
              builder: (context, state, child) {
                return Scaffold(
                  body: child,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex:
                        _calculateSelectedIndex(state.uri.toString()),
                    onDestinationSelected: (index) {
                      navigateToSelectedIndex(index, context);
                    },
                    destinations: const [
                      NavigationDestination(
                          icon: Icon(Icons.home), label: 'Home'),
                      NavigationDestination(
                          icon: Icon(Icons.smart_toy), label: 'Chat'),
                      NavigationDestination(
                          icon: Icon(Icons.person), label: 'Profile'),
                    ],
                  ),
                );
              },
              routes: [
                GoRoute(
                    path: '/', builder: (context, state) => const HomePage()),
                GoRoute(
                    path: '/ai', builder: (context, state) => const ChatPage()),
                GoRoute(
                    path: '/profile',
                    builder: (context, state) => const ProfilePage()),
              ],
            ),
          ],
          initialLocation: '/',
        );

        router.routerDelegate.addListener(() {
          final currentRoute =
              router.routerDelegate.currentConfiguration.uri.toString();
          PreferencesManager().setLastRoute(currentRoute);
        });

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Project Brain',
          routerConfig: router,
          themeMode: ThemeMode.system,
          theme: getTheme(),
          darkTheme: getDarkTheme(),
        );
      },
    );
  }

  void navigateToSelectedIndex(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/ai');
      case 2:
        context.go('/profile');
    }
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/ai')) return 1;
    return 0;
  }
}
