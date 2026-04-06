import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
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

  Auth0User? _profile;

  /// Whether the user is currently authenticated
  bool get isLoggedIn => _profile != null;

  /// The authenticated user's profile
  Auth0User? get profile => _profile;

  /// Constructor with dependency injection for testability
  AuthService({
    OAuthService? oauthService,
    TokenManager? tokenManager,
    TokenStorage? tokenStorage,
    UserProfileService? userProfileService,
  })  : _oauthService = oauthService ?? OAuthService(),
        _tokenManager = tokenManager ?? TokenManager(tokenStorage: TokenStorage()),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _userProfileService = userProfileService ?? UserProfileService();

  /// Initialize the auth service and attempt to restore previous session
  ///
  /// Returns true if a valid session was restored, false otherwise
  Future<bool> init() async {
    logInfo('[AuthService] Initializing...');

    try {
      Credentials? credentials =
          await _oauthService.tryRestoreCredentialsFromCredentialsManager();

      if (credentials == null) {
        final storedRefreshToken = await _tokenStorage.getRefreshToken();
        if (storedRefreshToken == null) {
          logDebug(
              '[AuthService] No CredentialsManager session or refresh token');
          return false;
        }
        logDebug('[AuthService] Refreshing session from stored refresh token');
        credentials =
            await _oauthService.refreshCredentials(storedRefreshToken);
      } else {
        logDebug('[AuthService] Using credentials from CredentialsManager');
      }

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
      logInfo('[AuthService] Session restored successfully');
      return true;
    } on ApiException catch (e) {
      logError('[AuthService] API error during init: ${e.message}', e);
      await _clearSession();
      return false;
    } catch (e, stackTrace) {
      logError('[AuthService] Unexpected error during init', e, stackTrace);
      await _clearSession();
      return false;
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
    logInfo('[AuthService] Login complete');
  }

  /// Log out the current user and clear all stored credentials
  Future<void> logout() async {
    logInfo('[AuthService] Logging out');

    // Perform Auth0 logout to clear SSO session
    try {
      await _oauthService.logout();
    } catch (e) {
      // Log but don't fail - we still want to clear local session
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

    if (credentials.refreshToken != null) {
      await _tokenStorage.saveRefreshToken(credentials.refreshToken!);
    }

    _tokenManager.setAccessToken(credentials.accessToken);

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
    _tokenManager.clearAccessToken();
    _profile = null;
  }

  /// Clean up resources
  void dispose() {
    _userProfileService.dispose();
  }
}
