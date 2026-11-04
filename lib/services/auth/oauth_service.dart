import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/storage/preferences_service.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';

/// Service responsible for handling Auth0 OAuth authentication flows
class OAuthService {
  final Auth0 _auth0;
  final PreferencesService? _preferencesService;
  final http.Client _httpClient;

  static const _revokeTimeout = Duration(seconds: 5);

  OAuthService({
    Auth0? auth0,
    PreferencesService? preferencesService,
    http.Client? httpClient,
  })  : _auth0 = auth0 ?? Auth0(AppConfig.authDomain, AppConfig.authClientId),
        _preferencesService = preferencesService,
        _httpClient = httpClient ?? http.Client();

  /// Initiate the login flow
  ///
  /// Set [requireReauthentication] to make Universal Login ask for the
  /// user's credentials even when an Auth0 SSO session cookie exists.
  ///
  /// Returns [Credentials] on success
  /// Throws [AuthException] if login fails
  Future<Credentials> login({bool requireReauthentication = false}) async {
    try {
      logDebug('[OAuthService] Starting login flow');

      final prefs = _preferencesService;
      final forceFreshLogin = prefs?.forceFreshLogin ?? false;
      final loginHint = forceFreshLogin || requireReauthentication
          ? null
          : prefs?.lastLoginEmail;

      final parameters = <String, String>{};
      if (forceFreshLogin || requireReauthentication) {
        parameters['prompt'] = 'login';
      } else if (loginHint != null && loginHint.isNotEmpty) {
        parameters['login_hint'] = loginHint;
      }

      final credentials = await _auth0.webAuthentication().login(
            useHTTPS: true,
            useEphemeralSession: false,
            audience: AppConfig.authAudience,
            scopes: {'openid', 'profile', 'offline_access', 'email'},
            redirectUrl: AppConfig.authRedirectUri,
            parameters: parameters,
          );

      await storeCredentials(credentials);

      if (forceFreshLogin) {
        await prefs?.clearForceFreshLogin();
      }

      logDebug('[OAuthService] Login successful');
      return credentials;
    } on WebAuthenticationException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        logDebug('[OAuthService] User cancelled login');
        throw AuthException('Login cancelled by user', e);
      }
      logDebug('[OAuthService] Web authentication error: ${e.message}');
      throw AuthException('Authentication failed: ${e.message}', e);
    } on PlatformException catch (e) {
      logDebug('[OAuthService] Platform error during login: ${e.message}');
      throw AuthException('Platform error: ${e.message ?? "Unknown error"}', e);
    } catch (e, stackTrace) {
      logDebug('[OAuthService] Unexpected error during login: $e');
      throw AuthException('Unexpected error during login', e, stackTrace);
    }
  }

  /// Log out: revokes [refreshToken] (when given) and clears Auth0-stored
  /// credentials. On iOS, skips hosted logout so ASWebAuthenticationSession
  /// does not run (avoids the system credential sheet).
  /// On other platforms, performs federated web logout then clears credentials.
  Future<void> logout({String? refreshToken}) async {
    try {
      logDebug('[OAuthService] Logging out');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await revokeRefreshToken(refreshToken);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await clearLocalCredentials();
      } else {
        await _auth0.webAuthentication().logout(
              returnTo: AppConfig.authRedirectUri,
              useHTTPS: true,
            );
        await clearLocalCredentials();
      }
      logDebug('[OAuthService] Logout complete');
    } catch (e, stackTrace) {
      logDebug('[OAuthService] Error during logout: $e');
      throw AuthException('Error during logout', e, stackTrace);
    }
  }

  /// Revoke [refreshToken] at Auth0 so a copy of it stops working after
  /// logout. Best effort: never throws, and gives up after a short timeout so
  /// an offline logout is not held up.
  Future<void> revokeRefreshToken(String refreshToken) async {
    try {
      final response = await _httpClient
          .post(
            Uri.https(AppConfig.authDomain, '/oauth/revoke'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_id': AppConfig.authClientId,
              'token': refreshToken,
            }),
          )
          .timeout(_revokeTimeout);
      if (response.statusCode == 200) {
        logDebug('[OAuthService] Refresh token revoked');
      } else {
        logWarning(
            '[OAuthService] Refresh token revoke failed: ${response.statusCode}');
      }
    } catch (e) {
      logWarning('[OAuthService] Refresh token revoke failed', e);
    }
  }

  /// Persist credentials in the native Auth0 CredentialsManager.
  Future<void> storeCredentials(Credentials credentials) async {
    try {
      await _auth0.credentialsManager.storeCredentials(credentials);
      logDebug('[OAuthService] Stored credentials in CredentialsManager');
    } catch (e) {
      logDebug('[OAuthService] Failed to store credentials: $e');
      rethrow;
    }
  }

  /// Clear credentials persisted by the native Auth0 SDK (CredentialsManager).
  ///
  /// Safe to call repeatedly; never throws so it can run during session
  /// teardown on every platform.
  Future<void> clearLocalCredentials() async {
    try {
      await _auth0.credentialsManager.clearCredentials();
      logDebug('[OAuthService] Cleared CredentialsManager');
    } catch (e) {
      logDebug('[OAuthService] CredentialsManager clear failed: $e');
    }
  }

  /// Refresh credentials using a refresh token
  ///
  /// Returns new [Credentials]
  /// Throws [ApiException] if refresh fails
  Future<Credentials> refreshCredentials(String refreshToken) async {
    logDebug('[OAuthService] Refreshing credentials');
    final credentials =
        await _auth0.api.renewCredentials(refreshToken: refreshToken);
    await storeCredentials(credentials);
    return credentials;
  }

  /// Returns true when CredentialsManager reports a valid (or refreshable) session.
  Future<bool> hasStoredCredentials({int minTtl = 60}) async {
    try {
      return await _auth0.credentialsManager.hasValidCredentials(
        minTtl: minTtl,
      );
    } catch (e) {
      logDebug('[OAuthService] hasStoredCredentials failed: $e');
      return false;
    }
  }

  /// Returns credentials persisted by the native SDK after [login], if valid.
  ///
  /// [minTtl] is the minimum remaining access token lifetime in seconds.
  Future<Credentials?> tryRestoreCredentialsFromCredentialsManager({
    int minTtl = 60,
  }) async {
    try {
      final has = await _auth0.credentialsManager.hasValidCredentials(
        minTtl: minTtl,
      );
      if (!has) {
        logDebug('[OAuthService] CredentialsManager has no valid credentials');
        return null;
      }
      final credentials = await _auth0.credentialsManager.credentials(
        minTtl: minTtl,
      );
      logDebug('[OAuthService] Restored credentials from CredentialsManager');
      return credentials;
    } on CredentialsManagerException catch (e) {
      logDebug('[OAuthService] CredentialsManager: ${e.message}');
      return null;
    } catch (e) {
      logDebug('[OAuthService] CredentialsManager restore failed: $e');
      return null;
    }
  }
}
