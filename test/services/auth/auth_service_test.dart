import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/auth/biometric_unlock_service.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class MockOAuthService extends Mock implements OAuthService {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockUserProfileService extends Mock implements UserProfileService {}

class MockBiometricUnlockService extends Mock
    implements BiometricUnlockService {}

String _jwtSegment(Map<String, dynamic> claims) {
  final json = utf8.encode(jsonEncode(claims));
  return base64Url.encode(json).replaceAll('=', '');
}

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
  late MockBiometricUnlockService mockBiometric;
  late PreferencesService preferences;
  late TokenManager tokenManager;
  late AuthService authService;

  setUpAll(() async {
    await initializeTestEnvironment();
    registerFallbackValue(
      testCredentials(
        accessToken:
            makeTestJwt({'aud': AppConfig.authAudience, 'exp': 9999999999}),
        idToken: makeTestJwt({'sub': 'x'}),
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = PreferencesService(prefs);

    mockOAuth = MockOAuthService();
    mockStorage = MockTokenStorage();
    mockProfile = MockUserProfileService();
    mockBiometric = MockBiometricUnlockService();
    when(() => mockStorage.clearAll()).thenAnswer((_) async {});
    when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);
    when(() => mockStorage.deleteRefreshToken()).thenAnswer((_) async {});
    when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
          minTtl: any(named: 'minTtl'),
        )).thenAnswer((_) async => null);
    when(() => mockOAuth.hasStoredCredentials(
          minTtl: any(named: 'minTtl'),
        )).thenAnswer((_) async => false);
    when(() => mockOAuth.clearLocalCredentials()).thenAnswer((_) async {});
    when(() => mockBiometric.isSupported()).thenAnswer((_) async => true);
    when(() => mockBiometric.unlockLabel())
        .thenAnswer((_) async => 'Unlock with Face ID');
    when(() => mockBiometric.authenticate(reason: any(named: 'reason')))
        .thenAnswer((_) async => true);

    tokenManager = TokenManager(
      auth0: Auth0(AppConfig.authDomain, AppConfig.authClientId),
    );
    authService = AuthService(
      oauthService: mockOAuth,
      tokenManager: tokenManager,
      tokenStorage: mockStorage,
      userProfileService: mockProfile,
      preferencesService: preferences,
      biometricUnlockService: mockBiometric,
    );
  });

  group('AuthService.init', () {
    test('uses CredentialsManager when it returns credentials', () async {
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
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
      when(() => mockProfile.getUserProfile(access))
          .thenAnswer((_) async => user);

      final ok = await authService.init();

      expect(ok, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.profile?.sub, 'auth0|cm');
      expect(authService.hasStoredSession, isTrue);

      verify(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).called(1);
      verifyNever(
          () => mockBiometric.authenticate(reason: any(named: 'reason')));
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(() => mockOAuth.refreshCredentials(any()));
    });

    test('migrates legacy refresh token when CredentialsManager is empty',
        () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
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
      verify(() => mockStorage.deleteRefreshToken()).called(1);
      verifyNever(() => mockStorage.saveRefreshToken(any()));
    });

    test('userinfo failure still restores session via ID token claims',
        () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => 'rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
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
      verifyNever(() => mockStorage.saveRefreshToken(any()));
    });

    test('ApiException during legacy migration clears legacy token', () async {
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => null);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'bad-rt');
      when(() => mockOAuth.refreshCredentials('bad-rt')).thenThrow(
        ApiException.unknown('invalid_grant'),
      );

      final ok = await authService.init();

      expect(ok, isFalse);
      verify(() => mockStorage.deleteRefreshToken()).called(1);
    });

    test('does not clear CredentialsManager on unexpected hydrate errors',
        () async {
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
      final creds = testCredentials(
        accessToken: access,
        idToken: '',
        refreshToken: 'rt',
      );
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => creds);
      when(() => mockProfile.getUserProfile(access))
          .thenThrow(Exception('network blip'));

      final ok = await authService.init();

      expect(ok, isFalse);
      verifyNever(() => mockOAuth.clearLocalCredentials());
    });
  });

  group('AuthService.init (biometric opt-in)', () {
    setUp(() async {
      await preferences.setBiometricUnlockEnabled(true);
    });

    test('prompts biometric then restores session when enabled', () async {
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
      final creds = testCredentials(
        accessToken: access,
        idToken: makeTestJwt({'sub': 'auth0|bio'}),
        refreshToken: 'bio-rt',
      );

      when(() => mockOAuth.hasStoredCredentials(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => true);
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
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

      final ok = await authService.init();

      expect(ok, isTrue);
      expect(authService.isLoggedIn, isTrue);
      verify(() => mockBiometric.authenticate(reason: any(named: 'reason')))
          .called(1);
      verifyNever(() => mockStorage.getRefreshToken());
    });

    test('keeps stored session when biometric is canceled', () async {
      when(() => mockOAuth.hasStoredCredentials(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => true);
      when(() => mockBiometric.authenticate(reason: any(named: 'reason')))
          .thenThrow(AuthException('Biometric authentication failed'));

      final ok = await authService.init();

      expect(ok, isFalse);
      expect(authService.awaitingBiometricUnlock, isTrue);
      expect(authService.hasStoredSession, isTrue);
      expect(
        authService.consumeLaunchAuthMessage(),
        contains('Biometric unlock'),
      );
      verifyNever(() => mockOAuth.clearLocalCredentials());
      verifyNever(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          ));
    });

    test('falls back to legacy migration when no stored credentials', () async {
      when(() => mockOAuth.hasStoredCredentials(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => false);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'legacy-rt');

      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
      final refreshed = testCredentials(
        accessToken: access,
        idToken: makeTestJwt({'sub': 'auth0|legacy'}),
        refreshToken: 'new-rt',
      );
      when(() => mockOAuth.refreshCredentials('legacy-rt'))
          .thenAnswer((_) async => refreshed);
      when(() => mockProfile.getUserProfile(access)).thenAnswer(
        (_) async => Auth0User(
          nickname: 'legacy',
          name: 'Legacy',
          email: 'l@test.com',
          picture: '',
          updatedAt: '2024-01-01T00:00:00.000Z',
          sub: 'auth0|legacy',
        ),
      );

      final ok = await authService.init();

      expect(ok, isTrue);
      verifyNever(
          () => mockBiometric.authenticate(reason: any(named: 'reason')));
    });
  });

  group('AuthService.unlockWithBiometrics', () {
    test('restores session after successful unlock', () async {
      await preferences.setBiometricUnlockEnabled(true);
      final access = makeTestJwt({
        'aud': AppConfig.authAudience,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
      final creds = testCredentials(
        accessToken: access,
        idToken: makeTestJwt({'sub': 'auth0|unlock'}),
        refreshToken: 'rt',
      );
      when(() => mockOAuth.tryRestoreCredentialsFromCredentialsManager(
            minTtl: any(named: 'minTtl'),
          )).thenAnswer((_) async => creds);
      when(() => mockProfile.getUserProfile(access)).thenAnswer(
        (_) async => Auth0User(
          nickname: 'u',
          name: 'Unlock',
          email: 'u@test.com',
          picture: '',
          updatedAt: '2024-01-01T00:00:00.000Z',
          sub: 'auth0|unlock',
        ),
      );

      final ok = await authService.unlockWithBiometrics();

      expect(ok, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.awaitingBiometricUnlock, isFalse);
    });
  });

  group('AuthService biometric preference', () {
    test('enableBiometricUnlock persists preference after prompt', () async {
      await authService.enableBiometricUnlock();
      expect(preferences.biometricUnlockEnabled, isTrue);
      verify(() => mockBiometric.authenticate(reason: any(named: 'reason')))
          .called(1);
    });

    test('logout clears biometric preference and credentials', () async {
      await preferences.setBiometricUnlockEnabled(true);
      when(() => mockOAuth.logout()).thenAnswer((_) async {});

      await authService.logout();

      expect(preferences.biometricUnlockEnabled, isFalse);
      verify(() => mockOAuth.clearLocalCredentials()).called(1);
    });
  });
}
