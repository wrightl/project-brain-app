import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/user_profile_service.dart';

import '../../helpers/test_helpers.dart';

class MockOAuthService extends Mock implements OAuthService {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockUserProfileService extends Mock implements UserProfileService {}

String _jwtSegment(Map<String, dynamic> claims) {
  final json = utf8.encode(jsonEncode(claims));
  return base64Url.encode(json).replaceAll('=', '');
}

/// Unsigned JWT for tests (signature not validated by our code).
String makeTestJwt(Map<String, dynamic> payload) {
  final header = _jwtSegment({'alg': 'none', 'typ': 'JWT'});
  final body = _jwtSegment(payload);
  return '$header.$body.x';
}

Credentials testCredentials({
  required String accessToken,
  required String idToken,
  String? refreshToken,
}) {
  return Credentials(
    idToken: idToken,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    scopes: const {'openid', 'profile', 'email', 'offline_access'},
    user: const UserProfile(sub: 'auth0|test'),
    tokenType: 'Bearer',
  );
}

void main() {
  late MockOAuthService mockOAuth;
  late MockTokenStorage mockStorage;
  late MockUserProfileService mockProfile;
  late TokenManager tokenManager;
  late AuthService authService;

  setUpAll(() async {
    await initializeTestEnvironment();
    registerFallbackValue(
      testCredentials(
        accessToken: makeTestJwt(
            {'aud': AppConfig.authAudience, 'exp': 9999999999}),
        idToken: makeTestJwt({'sub': 'x'}),
      ),
    );
  });

  setUp(() {
    mockOAuth = MockOAuthService();
    mockStorage = MockTokenStorage();
    mockProfile = MockUserProfileService();
    when(() => mockStorage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.clearAll()).thenAnswer((_) async {});
    when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);
    when(() => mockOAuth.tryRestoreCredentialsWithBiometric(
          minTtl: any(named: 'minTtl'),
        )).thenAnswer((_) async => null);
    tokenManager = TokenManager(
      auth0: Auth0(AppConfig.authDomain, AppConfig.authClientId),
      tokenStorage: mockStorage,
    );
    authService = AuthService(
      oauthService: mockOAuth,
      tokenManager: tokenManager,
      tokenStorage: mockStorage,
      userProfileService: mockProfile,
      enableBiometricLaunchGate: false,
    );
  });

  group('AuthService.init', () {
    test('uses CredentialsManager when it returns credentials', () async {
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
      });
      final id = makeTestJwt({'sub': 'auth0|cm', 'email': 'cm@test.com'});
      final creds = testCredentials(
        accessToken: access,
        idToken: id,
        refreshToken: 'rt-cm',
      );

      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => creds);

      final user = Auth0User(
        nickname: 'cm',
        name: 'CM',
        email: 'cm@test.com',
        picture: '',
        updatedAt: '2024-01-01T00:00:00.000Z',
        sub: 'auth0|cm',
      );
      when(() => mockProfile.getUserProfile(access)).thenAnswer((_) async => user);

      final ok = await authService.init();

      expect(ok, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.profile?.sub, 'auth0|cm');

      verify(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).called(1);
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(() => mockOAuth.refreshCredentials(any()));
    });

    test('falls back to refresh token when CredentialsManager is empty',
        () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
      });
      final id = makeTestJwt({'sub': 'auth0|rt'});
      final refreshed = testCredentials(
        accessToken: access,
        idToken: id,
        refreshToken: 'new-rt',
      );

      when(() => mockOAuth.refreshCredentials('stored-rt'))
          .thenAnswer((_) async => refreshed);

      when(() => mockProfile.getUserProfile(access)).thenAnswer(
        (_) async => Auth0User(
          nickname: 'n',
          name: 'Name',
          email: 'e@test.com',
          picture: '',
          updatedAt: '2024-01-01T00:00:00.000Z',
          sub: 'auth0|rt',
        ),
      );

      final ok = await authService.init();

      expect(ok, isTrue);
      verify(() => mockOAuth.refreshCredentials('stored-rt')).called(1);
    });

    test('persists refresh token before calling userinfo', () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
      });
      final creds = testCredentials(
        accessToken: access,
        idToken: makeTestJwt({'sub': 's'}),
        refreshToken: 'persist-me',
      );
      when(() => mockOAuth.refreshCredentials('rt'))
          .thenAnswer((_) async => creds);

      final order = <String>[];
      when(() => mockStorage.saveRefreshToken('persist-me'))
          .thenAnswer((_) async {
        order.add('saveRefresh');
      });
      when(() => mockProfile.getUserProfile(access)).thenAnswer((_) async {
        order.add('userinfo');
        return Auth0User(
          nickname: 'a',
          name: 'A',
          email: 'a@a.com',
          picture: '',
          updatedAt: '2024-01-01T00:00:00.000Z',
          sub: 'auth0|a',
        );
      });

      await authService.init();

      expect(order, ['saveRefresh', 'userinfo']);
    });

    test('userinfo failure still restores session via ID token claims',
        () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
      });
      final idPayload = {
        'sub': 'auth0|idt',
        'email': 'idt@test.com',
        'name': 'Id Token User',
        'nickname': 'idt',
        'picture': 'https://example.com/p.png',
        'updated_at': '2024-06-01T12:00:00.000Z',
      };
      final creds = testCredentials(
        accessToken: access,
        idToken: makeTestJwt(idPayload),
        refreshToken: 'rt2',
      );
      when(() => mockOAuth.refreshCredentials('rt'))
          .thenAnswer((_) async => creds);
      when(() => mockProfile.getUserProfile(access))
          .thenThrow(AuthException('userinfo down'));

      final ok = await authService.init();

      expect(ok, isTrue);
      expect(authService.profile?.sub, 'auth0|idt');
      expect(authService.profile?.email, 'idt@test.com');
      verify(() => mockStorage.saveRefreshToken('rt2')).called(1);
    });

    test('ApiException during refresh clears session', () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'bad-rt');
      when(() => mockOAuth.refreshCredentials('bad-rt')).thenThrow(
        ApiException.unknown('invalid_grant'),
      );
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      final ok = await authService.init();

      expect(ok, isFalse);
      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('AuthService.init (biometric launch gate)', () {
    late AuthService biometricAuthService;

    setUp(() {
      biometricAuthService = AuthService(
        oauthService: mockOAuth,
        tokenManager: tokenManager,
        tokenStorage: mockStorage,
        userProfileService: mockProfile,
        enableBiometricLaunchGate: true,
      );
    });

    test('restores session from biometric-gated credentials', () async {
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
      });
      final creds = testCredentials(
        accessToken: access,
        idToken: makeTestJwt({'sub': 'auth0|bio'}),
        refreshToken: 'bio-rt',
      );

      when(() => mockOAuth.tryRestoreCredentialsWithBiometric(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => creds);
      when(() => mockProfile.getUserProfile(access)).thenAnswer(
        (_) async => Auth0User(
          nickname: 'bio',
          name: 'Biometric User',
          email: 'bio@test.com',
          picture: '',
          updatedAt: '2024-01-01T00:00:00.000Z',
          sub: 'auth0|bio',
        ),
      );

      final ok = await biometricAuthService.init();

      expect(ok, isTrue);
      expect(biometricAuthService.isLoggedIn, isTrue);
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(() => mockOAuth.refreshCredentials(any()));
    });

    test('does not bypass biometric gate when canceled/failed', () async {
      when(() => mockOAuth.tryRestoreCredentialsWithBiometric(
            minTtl: any(named: 'minTtl'),
          )).thenThrow(AuthException('Biometric authentication failed'));

      final ok = await biometricAuthService.init();

      expect(ok, isFalse);
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(() => mockOAuth.refreshCredentials(any()));
    });

    test('returns logged-out when no biometric session is available', () async {
      when(() => mockOAuth.tryRestoreCredentialsWithBiometric(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);

      final ok = await biometricAuthService.init();

      expect(ok, isFalse);
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(() => mockOAuth.refreshCredentials(any()));
    });
  });
}
