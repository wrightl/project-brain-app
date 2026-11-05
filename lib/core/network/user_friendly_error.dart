import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:projectbrain/core/network/rate_limited_exception.dart';

const _offlineMessage =
    'You seem to be offline. Check your connection and try again.';
const _timeoutMessage = 'This is taking longer than usual. Please try again.';

// Services often wrap the original error in `Exception('...: $error')`, so
// the type is lost; these fragments still identify a network failure.
const _offlineHints = [
  'SocketException',
  'ClientException',
  'Failed host lookup',
  'Connection refused',
  'Connection reset',
  'Network is unreachable',
  'HandshakeException',
];

/// A message that is safe to show the user for [error].
///
/// Rate-limit messages come from the API and are shown as they are. Network
/// failures and timeouts get a plain explanation; anything else gets
/// [fallback]. Raw exception text (status codes, stack details) is never
/// returned; log [error] separately.
String userFriendlyError(Object error, {required String fallback}) {
  if (error is RateLimitedException) return error.message;
  if (error is TimeoutException) return _timeoutMessage;
  if (error is SocketException ||
      error is http.ClientException ||
      error is HandshakeException) {
    return _offlineMessage;
  }
  final text = error.toString();
  if (_offlineHints.any(text.contains)) return _offlineMessage;
  if (text.contains('TimeoutException')) return _timeoutMessage;
  return fallback;
}
