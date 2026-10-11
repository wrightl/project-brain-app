import 'dart:convert';

/// Thrown when the API answers 429: either the per-minute rate limit or a
/// daily/monthly usage quota. [message] is safe to show to the user.
class RateLimitedException implements Exception {
  static const String defaultMessage =
      "You're sending requests too quickly. Please wait a moment and try again.";

  RateLimitedException({String? message, this.retryAfter})
      : message = (message == null || message.trim().isEmpty)
            ? defaultMessage
            : message;

  /// Builds the exception from a 429 response. Quota rejections carry a
  /// user-facing `error` in a JSON body; rate-limit rejections have no body.
  factory RateLimitedException.fromResponse(
    String body,
    Map<String, String> headers,
  ) {
    return RateLimitedException(
      message: _errorFromBody(body),
      retryAfter: parseRetryAfter(headers),
    );
  }

  final String message;
  final Duration? retryAfter;

  /// Reads a delta-seconds `Retry-After` header; HTTP-date values are ignored.
  static Duration? parseRetryAfter(Map<String, String> headers) {
    final seconds = int.tryParse(headers['retry-after']?.trim() ?? '');
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  static String? _errorFromBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String) return error;
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on FormatException {
      // Not JSON; fall back to the default message.
    }
    return null;
  }

  @override
  String toString() => message;
}
