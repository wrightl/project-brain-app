import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';
import 'package:projectbrain/services/auth/user_profile_service.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';
import 'package:projectbrain/services/resource_service.dart';
import 'package:projectbrain/services/voice_note_service.dart';
import 'package:projectbrain/services/quiz_service.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/services/subscription_service.dart';
import 'package:projectbrain/services/egg_goals_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';
import 'package:projectbrain/services/journal_service.dart';
import 'package:projectbrain/services/strategy_service.dart';
import 'package:projectbrain/services/tag_service.dart';
import 'package:projectbrain/services/user_service.dart';
import 'package:projectbrain/services/push_notification_service.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/services/error_reporting_service.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/services/http_service.dart';
import 'package:projectbrain/core/routing/app_router.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Service Locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ===== External Dependencies =====
  // SharedPreferences - must be initialized asynchronously
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Logger - environment-aware logging that works in all build modes
  sl.registerLazySingleton<Logger>(
    () => AppLogger.instance,
  );

  // ===== Core Services =====
  // Preferences Service
  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesService(sl<SharedPreferences>()),
  );

  // ===== Authentication Services =====
  // Token Storage - handles secure storage of tokens
  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorage(),
  );

  // Token Manager - manages access token lifecycle
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(tokenStorage: sl<TokenStorage>()),
  );

  // OAuth Service - handles Auth0 OAuth flows
  sl.registerLazySingleton<OAuthService>(
    () => OAuthService(),
  );

  // User Profile Service - fetches user profile from Auth0
  sl.registerLazySingleton<UserProfileService>(
    () => UserProfileService(),
  );

  // Auth Service - orchestrates authentication operations
  sl.registerLazySingleton<AuthService>(
    () => AuthService(
      oauthService: sl<OAuthService>(),
      tokenManager: sl<TokenManager>(),
      tokenStorage: sl<TokenStorage>(),
      userProfileService: sl<UserProfileService>(),
    ),
  );

  // HTTP Service - base service for making authenticated API requests
  sl.registerLazySingleton<HttpService>(
    () => HttpService(authService: sl<AuthService>()),
  );

  // Feature Flag Service - manages feature flags from backend API
  sl.registerLazySingleton<FeatureFlagService>(
    () => FeatureFlagService(httpService: sl<HttpService>()),
  );

  // Auth Provider - manages authentication UI state
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      authService: sl<AuthService>(),
      featureFlagService: sl<FeatureFlagService>(),
    ),
  );

  // ===== API Services =====
  // AI Service
  sl.registerLazySingleton<AIService>(
    () => AIService(authService: sl<AuthService>()),
  );

  // Conversation Service
  sl.registerLazySingleton<ConversationService>(
    () => ConversationService(authService: sl<AuthService>()),
  );

  // Resource Service
  sl.registerLazySingleton<ResourceService>(
    () => ResourceService(authService: sl<AuthService>()),
  );

  // Voice Note Service
  sl.registerLazySingleton<VoiceNoteService>(
    () => VoiceNoteService(authService: sl<AuthService>()),
  );

  // Quiz Service
  sl.registerLazySingleton<QuizService>(
    () => QuizService(authService: sl<AuthService>()),
  );

  // Coach Service
  sl.registerLazySingleton<CoachService>(
    () => CoachService(authService: sl<AuthService>()),
  );

  // Subscription Service
  sl.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(authService: sl<AuthService>()),
  );

  // Egg Goals Service
  sl.registerLazySingleton<EggGoalsService>(
    () => EggGoalsService(authService: sl<AuthService>()),
  );

  // Goals Realtime (SSE) Service
  sl.registerLazySingleton<GoalsRealtimeService>(
    () => GoalsRealtimeService(authService: sl<AuthService>()),
  );

  // Journal Service
  sl.registerLazySingleton<JournalService>(
    () => JournalService(authService: sl<AuthService>()),
  );

  // Strategy Service
  sl.registerLazySingleton<StrategyService>(
    () => StrategyService(authService: sl<AuthService>()),
  );

  // Tag Service
  sl.registerLazySingleton<TagService>(
    () => TagService(authService: sl<AuthService>()),
  );

  // User Service (used by auth and journal timezone)
  sl.registerLazySingleton<UserService>(
    () => UserService(authService: sl<AuthService>()),
  );

  // Push Notification Service
  sl.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      httpService: sl<HttpService>(),
      authService: sl<AuthService>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // ===== Firebase Services =====
  // Firebase Analytics - singleton instance
  sl.registerLazySingleton<FirebaseAnalytics>(
    () => FirebaseAnalytics.instance,
  );

  // Firebase Crashlytics - singleton instance
  sl.registerLazySingleton<FirebaseCrashlytics>(
    () => FirebaseCrashlytics.instance,
  );

  // Error Reporting Service - combines Crashlytics and Analytics
  sl.registerLazySingleton<ErrorReportingService>(
    () => ErrorReportingService(
      crashlytics: sl<FirebaseCrashlytics>(),
      analytics: sl<FirebaseAnalytics>(),
    ),
  );

  // ===== Providers =====
  // Chat Provider - factory to create new instances when needed
  sl.registerFactory<ChatProvider>(
    () => ChatProvider(
      aiService: sl<AIService>(),
      conversationService: sl<ConversationService>(),
    ),
  );

  // Subscription Provider - manages subscription UI state
  sl.registerLazySingleton<SubscriptionProvider>(
    () => SubscriptionProvider(
      subscriptionService: sl<SubscriptionService>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Egg Goals Provider - manages daily goals UI state
  sl.registerLazySingleton<EggGoalsProvider>(
    () => EggGoalsProvider(
      eggGoalsService: sl<EggGoalsService>(),
      preferencesService: sl<PreferencesService>(),
    ),
  );

  // Journal Provider - factory so each consumer can get a fresh instance if needed
  sl.registerFactory<JournalProvider>(
    () => JournalProvider(
      journalService: sl<JournalService>(),
      tagService: sl<TagService>(),
      userService: sl<UserService>(),
    ),
  );

  // Strategies Provider - library (list, save, delete, rating); shared across home and library
  sl.registerLazySingleton<StrategiesProvider>(
    () => StrategiesProvider(strategyService: sl<StrategyService>()),
  );

  // Strategies Chat Provider - strategies-mode chat flow; single instance for conversation state
  sl.registerLazySingleton<StrategiesChatProvider>(
    () => StrategiesChatProvider(
      aiService: sl<AIService>(),
      strategyService: sl<StrategyService>(),
    ),
  );

  // ===== Routing =====
  // App Router - depends on auth provider, preferences service, and error reporting service
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(
      authProvider: sl<AuthProvider>(),
      preferencesService: sl<PreferencesService>(),
      errorReportingService: sl<ErrorReportingService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
