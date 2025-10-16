import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  List<Object?> get props => [message, stackTrace];

  @override
  String toString() => message;
}

/// Server-related failures (API errors, network issues, etc.)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(
    super.message, [
    this.statusCode,
    super.stackTrace,
  ]);

  @override
  List<Object?> get props => [message, statusCode, stackTrace];
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.stackTrace]);

  /// User cancelled the authentication flow
  factory AuthFailure.cancelled() =>
      const AuthFailure('Authentication cancelled by user');

  /// Invalid or expired credentials
  factory AuthFailure.invalidCredentials() =>
      const AuthFailure('Invalid credentials');

  /// No valid session found
  factory AuthFailure.noSession() => const AuthFailure('No active session');

  /// Token refresh failed
  factory AuthFailure.refreshFailed() => const AuthFailure('Failed to refresh token');
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);

  factory NetworkFailure.noConnection() =>
      const NetworkFailure('No internet connection');

  factory NetworkFailure.timeout() =>
      const NetworkFailure('Request timed out');
}

/// Validation-related failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, [
    this.fieldErrors,
    super.stackTrace,
  ]);

  @override
  List<Object?> get props => [message, fieldErrors, stackTrace];
}

/// Unexpected/unknown failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [super.stackTrace]);

  factory UnexpectedFailure.fromException(Exception e, [StackTrace? stackTrace]) {
    return UnexpectedFailure(e.toString(), stackTrace);
  }
}
