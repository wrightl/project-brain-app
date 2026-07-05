import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/auth0_id_token.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';

/// Service responsible for managing access tokens and refresh logic.
///
/// Uses in-memory [Credentials] as the active session and persists rotated
/// tokens to the native Auth0 [CredentialsManager] so refresh-token rotation
/// never leaves a stale copy in secondary storage.
class TokenManager {
  final Auth0 _auth0;

  Credentials? _credentials;

  // Token expiry buffer - refresh tokens 5 minutes before they expire
  static const _expiryBuffer = Duration(minutes: 5);

  /// Whether a valid access token is currently available
  bool get hasValidToken => _credentials?.accessToken.isNotEmpty ?? false;

  TokenManager({
    Auth0? auth0,
  }) : _auth0 = auth0 ?? Auth0(AppConfig.authDomain, AppConfig.authClientId);

  /// Get a valid access token, refreshing if necessary
  ///
  /// Throws [AuthException] if no valid token is available
  Future<String> getAccessToken() async {
    if (_credentials == null || _credentials!.accessToken.isEmpty) {
      throw AuthException('No access token available - user not logged in');
    }

    if (!await _ensureValidAccessToken()) {
      throw AuthException('Unable to obtain valid access token');
    }

    return _credentials!.accessToken;
  }

  /// Store full credentials in memory (used after login or session restore).
  void setCredentials(Credentials credentials) {
    _credentials = credentials;
    logDebug('[TokenManager] Credentials stored');
  }

  /// Store a new access token and extract its expiry.
  ///
  /// Prefer [setCredentials] so refresh-token rotation can persist correctly.
  void setAccessToken(String token) {
    final existing = _credentials;
    if (existing != null) {
      _credentials = Credentials(
        idToken: existing.idToken,
        accessToken: token,
        refreshToken: existing.refreshToken,
        expiresAt: _extractTokenExpiry(token) ?? existing.expiresAt,
        scopes: existing.scopes,
        user: existing.user,
        tokenType: existing.tokenType,
      );
    } else {
      _credentials = Credentials(
        idToken: '',
        accessToken: token,
        expiresAt: _extractTokenExpiry(token) ?? DateTime.now(),
        scopes: const {},
        user: const UserProfile(sub: ''),
        tokenType: 'Bearer',
      );
    }
    logDebug('[TokenManager] Access token stored');
  }

  /// Clear the stored credentials
  void clearAccessToken() {
    _credentials = null;
    logDebug('[TokenManager] Credentials cleared');
  }

  /// Check if the current token is expired
  bool isTokenExpired() {
    final expiry = _tokenExpiry;
    if (expiry == null) return true;
    final now = DateTime.now();
    final expiryWithBuffer = expiry.subtract(_expiryBuffer);
    return now.isAfter(expiryWithBuffer);
  }

  DateTime? get _tokenExpiry {
    final credentials = _credentials;
    if (credentials == null) return null;

    final fromJwt = _extractTokenExpiry(credentials.accessToken);
    if (fromJwt != null) return fromJwt;

    return credentials.expiresAt;
  }

  /// Ensure the access token is valid, refreshing if necessary
  Future<bool> _ensureValidAccessToken() async {
    if (_credentials == null) {
      return false;
    }

    final expiry = _tokenExpiry;
    if (expiry == null) {
      return false;
    }

    final now = DateTime.now();
    final expiryWithBuffer = expiry.subtract(_expiryBuffer);

    if (now.isBefore(expiryWithBuffer)) {
      return true;
    }

    logDebug(
        '[TokenManager] Access token expired or expiring soon, refreshing');

    final refreshToken = _credentials!.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      logDebug('[TokenManager] No refresh token available');
      return false;
    }

    try {
      final renewed = await _auth0.api.renewCredentials(
        refreshToken: refreshToken,
      );

      _credentials = renewed;
      await _auth0.credentialsManager.storeCredentials(renewed);
      logDebug('[TokenManager] Token refreshed and persisted');
      return true;
    } catch (e) {
      logWarning('[TokenManager] Failed to refresh token', e);
      clearAccessToken();
      return false;
    }
  }

  /// Extract expiry time from JWT access token
  DateTime? _extractTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      final exp = payload['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      logDebug('[TokenManager] Error extracting token expiry: $e');
      return null;
    }
  }

  /// Parse an ID token JWT and extract claims
  Auth0IdToken parseIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw AuthException('Invalid ID token format');
      }

      final Map<String, dynamic> json = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      return Auth0IdToken.fromJson(json);
    } catch (e) {
      throw AuthException('Failed to parse ID token', e);
    }
  }

  /// Validate that the token's audience matches the expected audience
  Future<bool> validateTokenAudience(String accessToken) async {
    try {
      final parts = accessToken.split('.');

      if (parts.length != 3) {
        logDebug(
            '[TokenManager] Token is not a JWT, skipping audience validation');
        return true;
      }

      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      final aud = payload['aud'];

      if (aud == null) {
        logDebug('[TokenManager] No audience claim in token');
        return true;
      }

      if (aud is String) {
        final isValid = aud == AppConfig.authAudience;
        if (!isValid) {
          logDebug(
              '[TokenManager] Audience mismatch: expected ${AppConfig.authAudience}, got $aud');
        }
        return isValid;
      } else if (aud is List) {
        final isValid = aud.contains(AppConfig.authAudience);
        if (!isValid) {
          logDebug(
              '[TokenManager] Audience mismatch: expected ${AppConfig.authAudience} in $aud');
        }
        return isValid;
      }

      logDebug('[TokenManager] Unexpected audience type: ${aud.runtimeType}');
      return false;
    } catch (e) {
      logDebug('[TokenManager] Error validating token audience: $e');
      return false;
    }
  }
}
