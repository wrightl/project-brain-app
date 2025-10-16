import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/authentication/login_page.dart';
import 'package:projectbrain/authentication/profile_page.dart';
import 'package:projectbrain/chat/chat_page.dart';
import 'package:projectbrain/home/home_page.dart';
import 'package:projectbrain/onboarding/onboarding_page.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';

/// Application router configuration
class AppRouter {
  final AuthProvider authProvider;
  final PreferencesService preferencesService;

  AppRouter({
    required this.authProvider,
    required this.preferencesService,
  });

  /// Create and configure the GoRouter instance
  GoRouter createRouter() {
    final router = GoRouter(
      refreshListenable: authProvider,
      redirect: _handleRedirect,
      routes: _routes,
      initialLocation: '/',
    );

    // Save route changes to preferences
    router.routerDelegate.addListener(() {
      final currentRoute = router.routerDelegate.currentConfiguration.uri.toString();
      preferencesService.setLastRoute(currentRoute);
    });

    return router;
  }

  /// Handle authentication-based redirects
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    if (authProvider.isLoading) return null;

    final loggedIn = authProvider.isLoggedIn;
    final onboarded = authProvider.onboardingComplete;
    final loggingIn = state.matchedLocation == '/login';
    final onboarding = state.matchedLocation == '/onboarding';

    // Redirect to login if not authenticated
    if (!loggedIn) return loggingIn ? null : '/login';

    // Redirect to onboarding if authenticated but not onboarded
    if (loggedIn && !onboarded && !onboarding) return '/onboarding';

    // Redirect to home if trying to access login/onboarding when already authenticated
    if (loggedIn && onboarded && (loggingIn || onboarding)) return '/';

    return null;
  }

  /// Application routes
  List<RouteBase> get _routes => [
        // Authentication Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),

        // Main App Shell with Bottom Navigation
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: child,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _calculateSelectedIndex(state.uri.toString()),
                onDestinationSelected: (index) {
                  _navigateToIndex(index, context);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.smart_toy),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/ai',
              builder: (context, state) => const ChatPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ];

  /// Calculate the selected navigation index based on current route
  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/ai')) return 1;
    return 0;
  }

  /// Navigate to a specific tab index
  void _navigateToIndex(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/ai');
      case 2:
        context.go('/profile');
    }
  }
}
