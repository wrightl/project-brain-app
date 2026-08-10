import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/services/auth/biometric_unlock_service.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/user_profile_service.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Unified authentication service that orchestrates OAuth, token management, and user profile operations
///
/// This service no longer extends ChangeNotifier - UI state management should be handled by providers/blocs
class AuthService {
  final OAuthService _oauthService;
  final TokenManager _tokenManager;
  final TokenStorage _tokenStorage;
  final UserProfileService _userProfileService;
  final PreferencesService? _preferencesService;
  final BiometricUnlockService _biometricUnlockService;
  String? _launchAuthMessage;
  bool _hasStoredSession = false;
  bool _awaitingBiometricUnlock = false;

  Auth0User? _profile;

  /// Whether the user is currently authenticated
  bool get isLoggedIn => _profile != null;

  /// The authenticated user's profile
  Auth0User? get profile => _profile;

  /// Whether CredentialsManager (or legacy storage) still has a session that
  /// can be unlocked without going through Universal Login.
  bool get hasStoredSession => _hasStoredSession;

  /// True when a stored session exists but biometric unlock was canceled/failed.
  bool get awaitingBiometricUnlock => _awaitingBiometricUnlock;

  /// Whether the user has opted into biometric unlock on this device.
  bool get isBiometricUnlockEnabled =>
      _preferencesService?.biometricUnlockEnabled ?? false;

  /// One-time launch auth message (e.g., biometric canceled by user).
  String? consumeLaunchAuthMessage() {
    final message = _launchAuthMessage;
    _launchAuthMessage = null;
    return message;
  }

  /// Constructor with dependency injection for testability
  AuthService({
    OAuthService? oauthService,
    TokenManager? tokenManager,
    TokenStorage? tokenStorage,
    UserProfileService? userProfileService,
    PreferencesService? preferencesService,
    BiometricUnlockService? biometricUnlockService,
  })  : _oauthService = oauthService ?? OAuthService(),
        _tokenManager = tokenManager ?? TokenManager(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _userProfileService = userProfileService ?? UserProfileService(),
        _preferencesService = preferencesService,
        _biometricUnlockService =
            biometricUnlockService ?? BiometricUnlockService();

  /// Initialize the auth service and attempt to restore previous session
  ///
  /// Returns true if a valid session was restored, false otherwise
  Future<bool> init() async {
    logInfo('[AuthService] Initializing...');
    _launchAuthMessage = null;
    _awaitingBiometricUnlock = false;
    _hasStoredSession = false;

    try {
      final biometricRequired = isBiometricUnlockEnabled;
      if (biometricRequired) {
        final hasSession = await _oauthService.hasStoredCredentials();
        _hasStoredSession = hasSession;
        if (!hasSession) {
          // Still allow legacy migration without biometric when nothing is stored.
          final migrated = await _migrateLegacyRefreshToken();
          if (migrated == null) {
            logDebug('[AuthService] No session available to restore');
            return false;
          }
          return await _completeRestore(migrated);
        }

        try {
          await _biometricUnlockService.authenticate(
            reason: 'Unlock Project Brain',
          );
        } on AuthException catch (e) {
          logWarning(
              '[AuthService] Auth init blocked by biometric/local auth', e);
          _awaitingBiometricUnlock = true;
          _launchAuthMessage =
              'Biometric unlock was canceled or failed. Unlock to continue.';
          return false;
        }
      }

      Credentials? credentials =
          await _oauthService.tryRestoreCredentialsFromCredentialsManager();

      credentials ??= await _migrateLegacyRefreshToken();

      if (credentials == null) {
        logDebug('[AuthService] No session available to restore');
        _hasStoredSession = false;
        return false;
      }

      _hasStoredSession = true;
      return await _completeRestore(credentials);
    } on ApiException catch (e) {
      logError('[AuthService] API error during init: ${e.message}', e);
      await _clearSession();
      return false;
    } catch (e, stackTrace) {
      logError('[AuthService] Unexpected error during init', e, stackTrace);
      // Do not wipe CredentialsManager on unexpected errors — session may still
      // be valid on the next launch.
      return false;
    }
  }

  /// Retry biometric unlock and restore the stored session (no Universal Login).
  Future<bool> unlockWithBiometrics() async {
    _launchAuthMessage = null;
    try {
      await _biometricUnlockService.authenticate(
        reason: 'Unlock Project Brain',
      );

      final credentials =
          await _oauthService.tryRestoreCredentialsFromCredentialsManager();
      if (credentials == null) {
        _hasStoredSession = false;
        _awaitingBiometricUnlock = false;
        _launchAuthMessage = 'No saved session found. Please log in.';
        return false;
      }

      _hasStoredSession = true;
      final ok = await _completeRestore(credentials);
      if (ok) {
        _awaitingBiometricUnlock = false;
      }
      return ok;
    } on AuthException catch (e) {
      logWarning('[AuthService] Biometric unlock failed', e);
      _awaitingBiometricUnlock = true;
      _launchAuthMessage =
          'Biometric unlock was canceled or failed. Unlock to continue.';
      return false;
    } catch (e, stackTrace) {
      logError('[AuthService] Unexpected error during biometric unlock', e,
          stackTrace);
      _awaitingBiometricUnlock = true;
      _launchAuthMessage = 'Unable to unlock session. Please try again.';
      return false;
    }
  }

  /// Whether the device supports biometric / device-credential unlock.
  Future<bool> isBiometricAvailable() => _biometricUnlockService.isSupported();

  /// Label for the unlock button on the login screen.
  Future<String> biometricUnlockLabel() =>
      _biometricUnlockService.unlockLabel();

  /// Enable biometric unlock after a successful confirmation prompt.
  Future<void> enableBiometricUnlock() async {
    final available = await isBiometricAvailable();
    if (!available) {
      throw AuthException('Biometric unlock is not available on this device');
    }
    await _biometricUnlockService.authenticate(
      reason: 'Enable biometric unlock for Project Brain',
    );
    await _preferencesService?.setBiometricUnlockEnabled(true);
    logInfo('[AuthService] Biometric unlock enabled');
  }

  /// Disable biometric unlock (does not clear Auth0 credentials).
  Future<void> disableBiometricUnlock() async {
    await _preferencesService?.setBiometricUnlockEnabled(false);
    logInfo('[AuthService] Biometric unlock disabled');
  }

  Future<bool> _completeRestore(Credentials credentials) async {
    if (credentials.accessToken.isEmpty) {
      await _clearSession();
      return false;
    }

    final isValidAudience =
        await _tokenManager.validateTokenAudience(credentials.accessToken);
    if (!isValidAudience) {
      logWarning('[AuthService] Invalid token audience, clearing session');
      await _clearSession();
      return false;
    }

    await _hydrateSessionFromCredentials(
      credentials,
      allowIdTokenProfileFallback: true,
    );
    _hasStoredSession = true;
    _awaitingBiometricUnlock = false;
    logInfo('[AuthService] Session restored successfully');
    return true;
  }

  /// One-time migration from legacy flutter_secure_storage refresh tokens.
  Future<Credentials?> _migrateLegacyRefreshToken() async {
    final legacyRefreshToken = await _tokenStorage.getRefreshToken();
    if (legacyRefreshToken == null || legacyRefreshToken.isEmpty) {
      return null;
    }

    logDebug(
        '[AuthService] Migrating legacy refresh token to CredentialsManager');
    try {
      final credentials =
          await _oauthService.refreshCredentials(legacyRefreshToken);
      await _tokenStorage.deleteRefreshToken();
      logInfo('[AuthService] Legacy refresh token migrated successfully');
      return credentials;
    } catch (e) {
      logWarning('[AuthService] Legacy refresh token migration failed', e);
      await _tokenStorage.deleteRefreshToken();
      return null;
    }
  }

  /// Initiate the login flow
  ///
  /// Throws [AuthException] if login fails
  Future<void> login() async {
    logInfo('[AuthService] Starting login');
    final credentials = await _oauthService.login();
    await _hydrateSessionFromCredentials(
      credentials,
      allowIdTokenProfileFallback: true,
    );
    _hasStoredSession = true;
    _awaitingBiometricUnlock = false;
    logInfo('[AuthService] Login complete');
  }

  /// Log out the current user and clear all stored credentials
  Future<void> logout() async {
    logInfo('[AuthService] Logging out');

    try {
      await _oauthService.logout();
    } catch (e) {
      logWarning('[AuthService] Error during remote logout', e);
    }

    await _clearSession();
    logInfo('[AuthService] Logout complete');
  }

  /// Get a valid access token, refreshing if necessary
  ///
  /// Throws [AuthException] if no valid token is available
  Future<String> getAccessToken() async {
    return await _tokenManager.getAccessToken();
  }

  /// Persist tokens, load access token into memory, then resolve profile.
  Future<void> _hydrateSessionFromCredentials(
    Credentials credentials, {
    required bool allowIdTokenProfileFallback,
  }) async {
    if (credentials.accessToken.isEmpty) {
      throw AuthException('Invalid credentials - missing access token');
    }

    _tokenManager.setCredentials(credentials);

    try {
      _profile =
          await _userProfileService.getUserProfile(credentials.accessToken);
    } catch (e, stackTrace) {
      logWarning('[AuthService] userinfo failed', e, stackTrace);
      if (!allowIdTokenProfileFallback) {
        rethrow;
      }
      final fromToken = _profileFromIdToken(credentials.idToken);
      if (fromToken == null) {
        throw AuthException('Failed to load profile', e);
      }
      _profile = fromToken;
      logInfo('[AuthService] Using ID token claims for profile');
    }
  }

  Auth0User? _profileFromIdToken(String idToken) {
    if (idToken.isEmpty) return null;
    try {
      final id = _tokenManager.parseIdToken(idToken);
      return Auth0User(
        nickname: id.nickname,
        name: id.name,
        email: id.email,
        picture: id.picture,
        updatedAt: id.updatedAt,
        sub: id.sub,
      );
    } catch (_) {
      return _profileFromJwtPayload(idToken);
    }
  }

  Auth0User? _profileFromJwtPayload(String idToken) {
    final json = _decodeJwtPayload(idToken);
    if (json == null) return null;

    String pick(String key, [String fallback = '']) {
      final v = json[key];
      if (v == null) return fallback;
      if (v is String) return v;
      return v.toString();
    }

    final sub = pick('sub');
    if (sub.isEmpty) return null;

    final email = pick('email');
    final name = pick('name', email.isNotEmpty ? email : 'User');
    final nickname = pick('nickname', name);
    final picture = pick('picture');
    final updatedAt = pick(
      'updated_at',
      DateTime.now().toUtc().toIso8601String(),
    );

    return Auth0User(
      nickname: nickname,
      name: name,
      email: email,
      picture: picture,
      updatedAt: updatedAt,
      sub: sub,
    );
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final jsonString = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clear all authentication data
  Future<void> _clearSession() async {
    await _tokenStorage.clearAll();
    await _oauthService.clearLocalCredentials();
    await _preferencesService?.clearBiometricUnlockEnabled();
    _tokenManager.clearAccessToken();
    _profile = null;
    _hasStoredSession = false;
    _awaitingBiometricUnlock = false;
  }

  /// Clean up resources
  void dispose() {
    _userProfileService.dispose();
  }
}
