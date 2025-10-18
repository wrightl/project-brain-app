/// Exception thrown when authentication operations fail
class AuthException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AuthException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'AuthException: $message';
}
