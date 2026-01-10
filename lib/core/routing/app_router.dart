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
import 'package:projectbrain/goals/goals_page.dart';
import 'package:projectbrain/goals/getting_started_page.dart';
import 'package:projectbrain/goals/goal_entry_page.dart';
import 'package:projectbrain/goals/goals_list_page.dart';
import 'package:projectbrain/goals/single_goal_celebration_page.dart';
import 'package:projectbrain/goals/all_goals_celebration_page.dart';
import 'package:projectbrain/core/routing/page_transitions.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Application router configuration
class AppRouter {
  final AuthProvider authProvider;
  final PreferencesService preferencesService;
  final ErrorReportingService errorReportingService;
  GoRouter? _router;

  AppRouter({
    required this.authProvider,
    required this.preferencesService,
    required this.errorReportingService,
  });

  /// Create and configure the GoRouter instance
  GoRouter createRouter() {
    _router = GoRouter(
      refreshListenable: authProvider,
      redirect: _handleRedirect,
      routes: _routes,
      initialLocation: '/',
    );

    // Save route changes to preferences and track screen views
    _router!.routerDelegate.addListener(() {
      final currentRoute =
          _router!.routerDelegate.currentConfiguration.uri.toString();
      preferencesService.setLastRoute(currentRoute);
      
      // Log screen view to analytics
      _logScreenView(currentRoute);
    });

    // Check for pending notification after router is ready
    _checkPendingNotification();

    return _router!;
  }

  /// Check for pending notification and navigate if needed
  void _checkPendingNotification() {
    // Use a post-frame callback to ensure router is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingNotification =
          sl<PushNotificationService>().getPendingNotification();
      if (pendingNotification != null && _router != null) {
        _navigateFromNotification(pendingNotification);
      }
    });
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    if (_router == null) return;

    try {
      final type = data['type'] as String?;
      logInfo('[AppRouter] Navigating from notification: type=$type');

      switch (type) {
        case 'coach_message':
          final coachId = data['coachId'] as String?;
          if (coachId != null) {
            _router!.go('/network/chat/$coachId');
          } else {
            _router!.go('/network');
          }
          break;
        case 'message':
          final messageId = data['messageId'] as String?;
          if (messageId != null) {
            // Navigate to chat or specific message
            _router!.go('/ai');
          }
          break;
        case 'coach_request':
          _router!.go('/network');
          break;
        case 'goal_reminder':
          _router!.go('/goals');
          break;
        default:
          // Navigate to home for unknown types
          _router!.go('/');
          break;
      }
    } catch (e, stackTrace) {
      logError('[AppRouter] Error navigating from notification', e, stackTrace);
    }
  }

  /// Public method to navigate from notification (called by push notification service)
  void navigateFromNotification(Map<String, dynamic> data) {
    _navigateFromNotification(data);
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
            GoRoute(
              path: '/goals',
              builder: (context, state) => const GoalsPage(),
            ),
            GoRoute(
              path: '/goals/getting-started',
              builder: (context, state) => const GettingStartedPage(),
            ),
            GoRoute(
              path: '/goals/entry',
              builder: (context, state) => const GoalEntryPage(),
            ),
            GoRoute(
              path: '/goals/list',
              builder: (context, state) => const GoalsListPage(),
            ),
          ],
        ),

        // Goals celebration routes (outside shell to avoid bottom nav)
        GoRoute(
          path: '/goals/celebration/single',
          pageBuilder: (context, state) {
            // Use slide-right transition (slides in from left)
            // When popped, reverse will slide goals list in from right (slide-left effect)
            return PageTransitions.slideLeft(
              key: state.pageKey,
              child: const SingleGoalCelebrationPage(),
            );
          },
        ),
        GoRoute(
          path: '/goals/celebration/all',
          pageBuilder: (context, state) {
            // Use slide-right transition (slides in from left)
            // When popped, reverse will slide goals list in from right (slide-left effect)
            return PageTransitions.slideLeft(
              key: state.pageKey,
              child: const AllGoalsCelebrationPage(),
            );
          },
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

  /// Log screen view to analytics
  void _logScreenView(String route) {
    try {
      // Convert route to a readable screen name
      final screenName = _getScreenName(route);
      errorReportingService.logScreenView(screenName);
    } catch (e) {
      logError('[AppRouter] Error logging screen view', e);
    }
  }

  /// Convert route path to a readable screen name
  String _getScreenName(String route) {
    // Remove leading slash and replace with readable format
    if (route == '/' || route.isEmpty) {
      return 'home';
    }
    
    // Remove query parameters and fragments
    final cleanRoute = route.split('?').first.split('#').first;
    
    // Convert path segments to readable format
    // e.g., /network/chat/123 -> network_chat
    // e.g., /goals/list -> goals_list
    final segments = cleanRoute.split('/').where((s) => s.isNotEmpty).toList();
    
    // Replace parameter placeholders with descriptive names
    final readableSegments = segments.map((segment) {
      // Handle parameterized routes
      if (segment.startsWith(':')) {
        return segment.substring(1); // Remove ':' prefix
      }
      return segment;
    }).toList();
    
    return readableSegments.join('_');
  }
}
