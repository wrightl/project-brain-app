import 'dart:async';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'dart:convert';
import '../../helpers/test_helpers.dart';

class MockAuth0 extends Mock implements Auth0 {}

class MockAuthenticationApi extends Mock implements AuthenticationApi {}

class MockCredentialsManager extends Mock implements CredentialsManager {}

void main() {
  late TokenManager tokenManager;

  setUpAll(() async {
    await initializeTestEnvironment();
  });

  setUp(() {
    tokenManager = TokenManager();
  });

  tearDownAll(() {
    resetTestEnvironment();
  });

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
      final token =
          createTestToken(DateTime.now().add(const Duration(hours: 1)));

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
      final token =
          createTestToken(DateTime.now().add(const Duration(hours: 1)));
      tokenManager.setAccessToken(token);

      tokenManager.clearAccessToken();

      expect(tokenManager.hasValidToken, isFalse);
    });

    test('hasValidToken returns correct state', () {
      expect(tokenManager.hasValidToken, isFalse);

      final token =
          createTestToken(DateTime.now().add(const Duration(hours: 1)));
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
      final nearExpiryToken = createTestToken(
        DateTime.now().add(const Duration(minutes: 3)),
      );
      tokenManager.setAccessToken(nearExpiryToken);

      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('isTokenExpired returns false for token beyond buffer', () {
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
      final header =
          base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
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

    test('validateTokenAudience returns true for token without audience',
        () async {
      final header =
          base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
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
      final header =
          base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode('{"sub":"1234567890","exp":"invalid"}'),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final token = '$header.$payload.$signature';

      tokenManager.setAccessToken(token);

      expect(tokenManager.hasValidToken, isTrue);
    });

    test('handles token without exp claim', () {
      final header =
          base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
      final payload = base64Url.encode(
        utf8.encode('{"sub":"1234567890","name":"Test"}'),
      );
      final signature = base64Url.encode(utf8.encode('signature'));
      final token = '$header.$payload.$signature';

      tokenManager.setAccessToken(token);

      expect(tokenManager.isTokenExpired(), isTrue);
    });

    test('handles empty token string', () {
      tokenManager.setAccessToken('');
      expect(tokenManager.hasValidToken, isFalse);
    });
  });

  group('TokenManager - Refresh', () {
    late MockAuth0 auth0;
    late MockAuthenticationApi api;
    late MockCredentialsManager credentialsManager;

    Credentials credentialsFor(String accessToken, String refreshToken) =>
        Credentials(
          idToken: '',
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          scopes: const {},
          user: const UserProfile(sub: 'auth0|user-1'),
          tokenType: 'Bearer',
        );

    setUpAll(() {
      registerFallbackValue(credentialsFor('', ''));
    });

    setUp(() {
      auth0 = MockAuth0();
      api = MockAuthenticationApi();
      credentialsManager = MockCredentialsManager();
      when(() => auth0.api).thenReturn(api);
      when(() => auth0.credentialsManager).thenReturn(credentialsManager);
      when(() => credentialsManager.storeCredentials(any()))
          .thenAnswer((_) async => true);
    });

    test('concurrent callers share a single refresh', () async {
      final manager = TokenManager(auth0: auth0);
      final expired =
          createTestToken(DateTime.now().subtract(const Duration(minutes: 1)));
      final fresh =
          createTestToken(DateTime.now().add(const Duration(hours: 1)));
      manager.setCredentials(credentialsFor(expired, 'refresh-1'));

      final renewal = Completer<Credentials>();
      when(() => api.renewCredentials(refreshToken: 'refresh-1'))
          .thenAnswer((_) => renewal.future);

      final requests = List.generate(5, (_) => manager.getAccessToken());
      renewal.complete(credentialsFor(fresh, 'refresh-2'));
      final tokens = await Future.wait(requests);

      expect(tokens, everyElement(fresh));
      verify(() => api.renewCredentials(refreshToken: 'refresh-1')).called(1);
    });

    test('a later expiry starts a new refresh with the rotated token',
        () async {
      final manager = TokenManager(auth0: auth0);
      final expired =
          createTestToken(DateTime.now().subtract(const Duration(minutes: 1)));
      manager.setCredentials(credentialsFor(expired, 'refresh-1'));

      when(() => api.renewCredentials(refreshToken: 'refresh-1'))
          .thenAnswer((_) async => credentialsFor(expired, 'refresh-2'));
      when(() => api.renewCredentials(refreshToken: 'refresh-2'))
          .thenAnswer((_) async => credentialsFor(expired, 'refresh-3'));

      await manager.getAccessToken().catchError((_) => '');
      await manager.getAccessToken().catchError((_) => '');

      verify(() => api.renewCredentials(refreshToken: 'refresh-1')).called(1);
      verify(() => api.renewCredentials(refreshToken: 'refresh-2')).called(1);
    });

    test('failed refresh clears the session for every waiting caller',
        () async {
      final manager = TokenManager(auth0: auth0);
      final expired =
          createTestToken(DateTime.now().subtract(const Duration(minutes: 1)));
      manager.setCredentials(credentialsFor(expired, 'refresh-1'));
      when(() => api.renewCredentials(refreshToken: 'refresh-1'))
          .thenThrow(Exception('invalid_grant'));

      final results = await Future.wait(List.generate(
        3,
        (_) =>
            manager.getAccessToken().then((_) => true, onError: (_) => false),
      ));

      expect(results, everyElement(isFalse));
      expect(manager.hasValidToken, isFalse);
      verify(() => api.renewCredentials(refreshToken: 'refresh-1')).called(1);
    });
  });
}
