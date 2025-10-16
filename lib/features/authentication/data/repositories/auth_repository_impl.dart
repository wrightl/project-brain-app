import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/entities/user_entity.dart';
import 'package:projectbrain/features/authentication/domain/repositories/auth_repository.dart';
import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/services/user_service.dart';

/// Implementation of AuthRepository using AuthService and UserService
class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  final UserService userService;

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  AuthRepositoryImpl({
    required this.authService,
    required this.userService,
  });

  @override
  bool get isAuthenticated => authService.isLoggedIn;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<Either<Failure, bool>> initialize() async {
    try {
      debugPrint('[AuthRepository] Initializing...');
      final success = await authService.init();
      _authStateController.add(success);
      return Right(success);
    } on AuthException catch (e, stackTrace) {
      debugPrint('[AuthRepository] Auth error during init: ${e.message}');
      return Left(AuthFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Unexpected error during init: $e');
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login() async {
    try {
      debugPrint('[AuthRepository] Performing login...');
      await authService.login();
      _authStateController.add(true);

      // Fetch user data after successful login
      return await getCurrentUser();
    } on AuthException catch (e, stackTrace) {
      debugPrint('[AuthRepository] Auth error during login: ${e.message}');

      if (e.message.contains('cancelled')) {
        return Left(AuthFailure.cancelled());
      }

      return Left(AuthFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Unexpected error during login: $e');
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      debugPrint('[AuthRepository] Performing logout...');
      await authService.logout();
      _authStateController.add(false);
      return const Right(unit);
    } on AuthException catch (e, stackTrace) {
      debugPrint('[AuthRepository] Auth error during logout: ${e.message}');
      return Left(AuthFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Unexpected error during logout: $e');
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      debugPrint('[AuthRepository] Fetching current user...');
      final userData = await userService.getCurrentUser();
      final user = User.fromJson(userData);

      return Right(_mapUserToEntity(user));
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Error fetching user: $e');

      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        return Left(AuthFailure.noSession());
      }

      return Left(ServerFailure(e.toString(), null, stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> completeOnboarding(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      debugPrint('[AuthRepository] Completing onboarding...');
      await userService.completeOnboarding(onboardingData);

      // Fetch updated user data
      return await getCurrentUser();
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Error completing onboarding: $e');
      return Left(ServerFailure(e.toString(), null, stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshUserData() async {
    return await getCurrentUser();
  }

  @override
  Future<Either<Failure, String>> getAccessToken() async {
    try {
      final token = await authService.getAccessToken();
      return Right(token);
    } on AuthException catch (e, stackTrace) {
      debugPrint('[AuthRepository] Error getting access token: ${e.message}');
      return Left(AuthFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Unexpected error getting token: $e');
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  /// Map User model to UserEntity
  UserEntity _mapUserToEntity(User user) {
    return UserEntity(
      id: user.id,
      email: user.email,
      name: user.name,
      nickname: user.nickname,
      picture: user.picture,
      bio: user.bio,
      isOnboarded: user.isOnboarded,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Clean up resources
  void dispose() {
    _authStateController.close();
  }
}
