import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'dart:convert';
import '../../helpers/test_helpers.dart';

// Mock classes
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late TokenManager tokenManager;
  late MockTokenStorage mockTokenStorage;

  setUpAll(() async {
    // Initialize test environment once for all tests
    await initializeTestEnvironment();
  });

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    tokenManager = TokenManager(tokenStorage: mockTokenStorage);
  });

  tearDownAll(() {
    resetTestEnvironment();
  });

  // Helper function to create a JWT token with specific expiry
  String createTestToken(DateTime expiry) {
    final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
    final payload = base64Url.encode(
      utf8.encode(
        '{"sub":"1234567890","name":"Test User","exp":${expiry.millisecondsSinceEpoch ~/ 1000}}',
      ),
    );
    final signature = base64Url.encode(utf8.encode('signature'));
    return '$header.$payload.$signature';
  }

  group('TokenManager - Token Storage', () {
    test('setAccessToken stores token', () {
      final token = createTestToken(DateTime.now().add(const Duration(hours: 1)));

      tokenManager.setAccessToken(token);

      expect(tokenManager.hasValidToken, isTrue);
    });

    test('getAccessToken throws when no token is set', () async {
      expect(
        () async => await tokenManager.getAccessToken(),
        throwsA(isA<AuthException>()),
      );
    });

    test('clearAccessToken removes stored token', () {
      final token = createTestToken(DateTime.now().add(const Duration(hours: 1)));
      tokenManager.setAccessToken(token);

      tokenManager.clearAccessToken();

      expect(tokenManager.hasValidToken, isFalse);
    });

    test('hasValidToken returns correct state', () {
      expect(tokenManager.hasValidToken, isFalse);

      final token = createTestToken(DateTime.now().add(const Duration(hours: 1)));
      tokenManager.setAccessToken(token);

      expect(tokenManager.hasValidToken, isTrue);
    });
  });

  group('TokenManager - Token Expiry', () {
    test('isTokenExpired returns true when no token is set', () {
      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('isTokenExpired returns true for expired token', () {
      final expiredToken = createTestToken(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      tokenManager.setAccessToken(expiredToken);

      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('isTokenExpired returns false for valid token', () {
      final validToken = createTestToken(
        DateTime.now().add(const Duration(hours: 1)),
      );
      tokenManager.setAccessToken(validToken);

      expect(tokenManager.isTokenExpired(), isFalse);
    });

    test('isTokenExpired accounts for expiry buffer', () {
      // Token expires in 3 minutes (less than 5-minute buffer)
      final nearExpiryToken = createTestToken(
        DateTime.now().add(const Duration(minutes: 3)),
      );
      tokenManager.setAccessToken(nearExpiryToken);

      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('isTokenExpired returns false for token beyond buffer', () {
      // Token expires in 10 minutes (more than 5-minute buffer)
      final safeToken = createTestToken(
        DateTime.now().add(const Duration(minutes: 10)),
      );
      tokenManager.setAccessToken(safeToken);

      expect(tokenManager.isTokenExpired(), isFalse);
    });

    test('getAccessToken succeeds with valid token', () async {
      final validToken = createTestToken(
        DateTime.now().add(const Duration(hours: 1)),
      );
      tokenManager.setAccessToken(validToken);

      final token = await tokenManager.getAccessToken();
      expect(token, equals(validToken));
    });
  });

  group('TokenManager - JWT Parsing', () {
    test('parseIdToken successfully parses valid JWT', () {
      final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode(
          '{"sub":"auth0|123","name":"Test User","email":"test@example.com",'
          '"nickname":"testuser","picture":"https://example.com/pic.jpg",'
          '"updated_at":"2024-01-01T00:00:00.000Z","iss":"https://test.auth0.com/",'
          '"aud":"test_audience","iat":1704067200,"exp":1704153600}',
        ),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final idToken = '$header.$payload.$signature';

      final parsed = tokenManager.parseIdToken(idToken);

      expect(parsed.sub, equals('auth0|123'));
      expect(parsed.name, equals('Test User'));
      expect(parsed.email, equals('test@example.com'));
    });

    test('parseIdToken throws on invalid JWT format', () {
      expect(
        () => tokenManager.parseIdToken('invalid.token'),
        throwsA(isA<AuthException>()),
      );
    });

    test('parseIdToken throws on malformed JWT', () {
      expect(
        () => tokenManager.parseIdToken('not_a_token'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('TokenManager - Token Validation', () {
    test('validateTokenAudience returns true for non-JWT tokens', () async {
      final result = await tokenManager.validateTokenAudience('not_a_jwt');
      expect(result, isTrue);
    });

    test('validateTokenAudience returns true for token without audience', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode('{"sub":"1234567890","name":"Test User"}'),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final token = '$header.$payload.$signature';

      final result = await tokenManager.validateTokenAudience(token);
      expect(result, isTrue);
    });
  });

  group('TokenManager - Edge Cases', () {
    test('handles token with invalid exp claim gracefully', () {
      final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode('{"sub":"1234567890","exp":"invalid"}'),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final token = '$header.$payload.$signature';

      tokenManager.setAccessToken(token);

      // Should handle gracefully
      expect(tokenManager.hasValidToken, isTrue);
    });

    test('handles token without exp claim', () {
      final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode('{"sub":"1234567890","name":"Test"}'),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final token = '$header.$payload.$signature';

      tokenManager.setAccessToken(token);

      // Token without expiry should be considered expired
      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('handles empty token string', () {
      tokenManager.setAccessToken('');
      expect(tokenManager.hasValidToken, isTrue); // Token is set, even if empty
    });
  });
}
