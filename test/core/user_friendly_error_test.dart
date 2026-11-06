import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/core/network/rate_limited_exception.dart';
import 'package:projectbrain/core/network/user_friendly_error.dart';

void main() {
  const fallback = "Couldn't load coaches.";

  test('passes rate-limit messages through', () {
    expect(
      userFriendlyError(RateLimitedException(message: 'Daily limit reached'),
          fallback: fallback),
      'Daily limit reached',
    );
  });

  test('explains network failures, even when wrapped', () {
    expect(userFriendlyError(const SocketException('x'), fallback: fallback),
        contains('offline'));
    expect(
      userFriendlyError(
        Exception('Failed to fetch coaches: SocketException: Failed host '
            'lookup: api.example.com'),
        fallback: fallback,
      ),
      contains('offline'),
    );
  });

  test('explains timeouts', () {
    expect(userFriendlyError(TimeoutException('x'), fallback: fallback),
        contains('longer than usual'));
  });

  test('never returns raw exception text', () {
    expect(
      userFriendlyError(Exception('Failed: 500 Internal Server Error {...}'),
          fallback: fallback),
      fallback,
    );
  });
}
