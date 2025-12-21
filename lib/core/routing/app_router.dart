import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/authentication/login_page.dart';
import 'package:projectbrain/user/profile_page.dart';
import 'package:projectbrain/chat/chat_page.dart';
import 'package:projectbrain/home/home_page.dart';
import 'package:projectbrain/onboarding/onboarding_page.dart';
import 'package:projectbrain/resources/resources_page.dart';
import 'package:projectbrain/user/user_page.dart';
import 'package:projectbrain/user/quizzes_page.dart';
import 'package:projectbrain/user/quiz_taking_page.dart';
import 'package:projectbrain/voicenotes/voice_notes_page.dart';
import 'package:projectbrain/network/network_page.dart';
import 'package:projectbrain/network/coach_chat_page.dart';
import 'package:projectbrain/network/find_coach_page.dart';
import 'package:projectbrain/network/coach_details_page.dart';
import 'package:projectbrain/network/coaches_list_page.dart';
import 'package:projectbrain/subscription/subscription_management_page.dart';
import 'package:projectbrain/subscription/pricing_page.dart';
import 'package:projectbrain/subscription/usage_dashboard_page.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/widgets/custom_bottom_nav_bar.dart';

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
      final currentRoute =
          router.routerDelegate.currentConfiguration.uri.toString();
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
            final selectedIndex = _calculateSelectedIndex(state.uri.toString());
            return Scaffold(
              body: child,
              bottomNavigationBar: selectedIndex >= 0
                  ? CustomBottomNavBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) {
                        _navigateToIndex(index, context);
                      },
                    )
                  : null,
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
              path: '/resources',
              builder: (context, state) => const ResourcesPage(),
            ),
            GoRoute(
              path: '/user',
              builder: (context, state) => const UserPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: '/voicenotes',
              builder: (context, state) => const VoiceNotesPage(),
            ),
            GoRoute(
              path: '/quizzes',
              builder: (context, state) => const QuizzesPage(),
            ),
            GoRoute(
              path: '/quizzes/:quizId',
              builder: (context, state) {
                final quizId = state.pathParameters['quizId']!;
                return QuizTakingPage(quizId: quizId);
              },
            ),
            GoRoute(
              path: '/network',
              builder: (context, state) => const NetworkPage(),
            ),
            GoRoute(
              path: '/network/coaches',
              builder: (context, state) => const CoachesListPage(),
            ),
            GoRoute(
              path: '/network/chat/:coachId',
              builder: (context, state) {
                final coachId = state.pathParameters['coachId']!;
                return CoachChatPage(coachId: coachId);
              },
            ),
            GoRoute(
              path: '/network/chat',
              builder: (context, state) => const CoachChatPage(),
            ),
            GoRoute(
              path: '/network/find',
              builder: (context, state) => const FindCoachPage(),
            ),
            GoRoute(
              path: '/network/coaches/:coachId',
              builder: (context, state) {
                final coachId = state.pathParameters['coachId']!;
                return CoachDetailsPage(coachId: coachId);
              },
            ),
          ],
        ),

        // Subscription Routes (outside shell to avoid bottom nav)
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => const SubscriptionManagementPage(),
        ),
        GoRoute(
          path: '/subscriptions/pricing',
          builder: (context, state) => const PricingPage(),
        ),
        GoRoute(
          path: '/subscriptions/usage',
          builder: (context, state) => const UsageDashboardPage(),
        ),
      ];

  /// Calculate the selected navigation index based on current route
  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/subscriptions')) {
      // Subscription pages don't have bottom nav, return -1 or handle separately
      return -1;
    }
    if (location.startsWith('/user') ||
        location.startsWith('/profile') ||
        location.startsWith('/voicenotes') ||
        location.startsWith('/quizzes') ||
        location.startsWith('/resources')) {
      return 3;
    }
    if (location.startsWith('/network')) return 2;
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
        context.go('/network');
      case 3:
        context.go('/user');
    }
  }
}
