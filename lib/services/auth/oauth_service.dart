import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
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

  /// Log out the current user from Auth0 (clears SSO session)
  Future<void> logout() async {
    try {
      logDebug('[OAuthService] Logging out');
      await _auth0.webAuthentication().logout(
            returnTo: AppConfig.authRedirectUri,
            // Must match [login] so iOS/macOS builds the same redirect URL mode;
            // mismatch often causes Auth0 "Oops" and leaves the hosted session active.
            useHTTPS: true,
          );
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
}
