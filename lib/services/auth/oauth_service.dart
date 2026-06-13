import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';

/// Service responsible for handling Auth0 OAuth authentication flows
class OAuthService {
  final Auth0 _auth0;

  OAuthService({Auth0? auth0})
      : _auth0 = auth0 ?? Auth0(AppConfig.authDomain, AppConfig.authClientId);

  /// Initiate the login flow
  ///
  /// Returns [Credentials] on success
  /// Throws [AuthException] if login fails
  Future<Credentials> login() async {
    try {
      logDebug('[OAuthService] Starting login flow');
      final credentials = await _auth0.webAuthentication().login(
            useHTTPS: true,
            useEphemeralSession: true,
            audience: AppConfig.authAudience,
            scopes: {'openid', 'profile', 'offline_access', 'email'},
            redirectUrl: AppConfig.authRedirectUri,
            // Avoid silent SSO / consent-only when an Auth0 session still exists;
            // forces identifier + credentials on Universal Login.
            parameters: const {'prompt': 'select_account'},
          );

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

  /// Log out: clears Auth0-stored credentials. On iOS, skips hosted logout so
  /// ASWebAuthenticationSession does not run (avoids the system credential sheet).
  /// On other platforms, performs federated web logout then clears credentials.
  Future<void> logout() async {
    try {
      logDebug('[OAuthService] Logging out');
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _auth0.credentialsManager.clearCredentials();
      } else {
        await _auth0.webAuthentication().logout(
              returnTo: AppConfig.authRedirectUri,
              // Must match [login] so iOS/macOS builds the same redirect URL mode;
              // mismatch often causes Auth0 "Oops" and leaves the hosted session active.
              useHTTPS: true,
            );
      }
      logDebug('[OAuthService] Logout complete');
    } catch (e, stackTrace) {
      logDebug('[OAuthService] Error during logout: $e');
      throw AuthException('Error during logout', e, stackTrace);
    }
  }

  /// Refresh credentials using a refresh token
  ///
  /// Returns new [Credentials]
  /// Throws [ApiException] if refresh fails
  Future<Credentials> refreshCredentials(String refreshToken) async {
    logDebug('[OAuthService] Refreshing credentials');
    return await _auth0.api.renewCredentials(refreshToken: refreshToken);
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

  /// Returns credentials from CredentialsManager, requiring local auth when configured.
  ///
  /// Returns null when no session is available. Throws [AuthException] when
  /// a biometric/local-auth challenge fails or is canceled.
  Future<Credentials?> tryRestoreCredentialsWithBiometric({
    int minTtl = 60,
  }) async {
    try {
      final credentials = await _auth0.credentialsManager.credentials(
        minTtl: minTtl,
      );
      logDebug('[OAuthService] Restored credentials with biometric gate');
      return credentials;
    } on CredentialsManagerException catch (e) {
      // No credentials available to restore: treat as logged out.
      if (e.isNoCredentialsFound || e.isNoRefreshTokenFound) {
        logDebug('[OAuthService] No stored credentials for biometric restore');
        return null;
      }

      // Token renewal failed from stale/invalid stored credentials.
      if (e.isTokenRenewFailed) {
        logDebug('[OAuthService] Stored credentials could not be renewed');
        return null;
      }

      // Any remaining credentials manager errors are treated as local-auth denial.
      logDebug('[OAuthService] Biometric/local auth failed: ${e.message}');
      throw AuthException('Biometric authentication failed', e);
    } catch (e, stackTrace) {
      logDebug('[OAuthService] Biometric restore failed: $e');
      throw AuthException(
        'Failed to restore session with biometric authentication',
        e,
        stackTrace,
      );
    }
  }
}
