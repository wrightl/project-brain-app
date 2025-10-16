import 'package:dartz/dartz.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/entities/user_entity.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Check if user is currently authenticated
  bool get isAuthenticated;

  /// Stream of authentication state changes
  Stream<bool> get authStateChanges;

  /// Initialize authentication service and restore session if available
  Future<Either<Failure, bool>> initialize();

  /// Perform login flow
  Future<Either<Failure, UserEntity>> login();

  /// Perform logout
  Future<Either<Failure, Unit>> logout();

  /// Get current authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Complete onboarding for the current user
  Future<Either<Failure, UserEntity>> completeOnboarding(
    Map<String, dynamic> onboardingData,
  );

  /// Refresh user data from server
  Future<Either<Failure, UserEntity>> refreshUserData();

  /// Get a valid access token (refreshing if necessary)
  Future<Either<Failure, String>> getAccessToken();
}
