import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';
import 'package:projectbrain/services/log_service.dart';
import 'package:projectbrain/core/routing/app_router.dart';

/// Service Locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ===== External Dependencies =====
  // SharedPreferences - must be initialized asynchronously
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Logger
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(),
      output: LogService(),
    ),
  );

  // ===== Core Services =====
  // Preferences Service
  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesService(sl<SharedPreferences>()),
  );

  // ===== Authentication =====
  // Auth Service - singleton to maintain authentication state
  sl.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  // Auth Provider
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(authService: sl<AuthService>()),
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

  // ===== Providers =====
  // Chat Provider - factory to create new instances when needed
  sl.registerFactory<ChatProvider>(
    () => ChatProvider(
      aiService: sl<AIService>(),
      conversationService: sl<ConversationService>(),
    ),
  );

  // ===== Routing =====
  // App Router - depends on auth provider and preferences service
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(
      authProvider: sl<AuthProvider>(),
      preferencesService: sl<PreferencesService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
