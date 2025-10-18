import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/models/auth0_id_token.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/services/auth/token_storage.dart';

/// Service responsible for managing access tokens and refresh logic
class TokenManager {
  final Auth0 _auth0;
  final TokenStorage _tokenStorage;

  String? _accessToken;
  DateTime? _tokenExpiry;

  // Token expiry buffer - refresh tokens 5 minutes before they expire
  static const _expiryBuffer = Duration(minutes: 5);

  /// Whether a valid access token is currently available
  bool get hasValidToken => _accessToken != null;

  TokenManager({
    Auth0? auth0,
    required TokenStorage tokenStorage,
  })  : _auth0 = auth0 ?? Auth0(AppConfig.authDomain, AppConfig.authClientId),
        _tokenStorage = tokenStorage;

  /// Get a valid access token, refreshing if necessary
  ///
  /// Throws [AuthException] if no valid token is available
  Future<String> getAccessToken() async {
    if (_accessToken == null) {
      throw AuthException('No access token available - user not logged in');
    }

    // Check if token needs refresh
    if (!await _ensureValidAccessToken()) {
      throw AuthException('Unable to obtain valid access token');
    }

    return _accessToken!;
  }

  /// Store a new access token and extract its expiry
  void setAccessToken(String token) {
    _accessToken = token;
    _tokenExpiry = _extractTokenExpiry(token);
    logDebug('[TokenManager] Access token stored');
  }

  /// Clear the stored access token
  void clearAccessToken() {
    _accessToken = null;
    _tokenExpiry = null;
    logDebug('[TokenManager] Access token cleared');
  }

  /// Check if the current token is expired
  bool isTokenExpired() {
    if (_tokenExpiry == null) return true;
    final now = DateTime.now();
    final expiryWithBuffer = _tokenExpiry!.subtract(_expiryBuffer);
    return now.isAfter(expiryWithBuffer);
  }

  /// Ensure the access token is valid, refreshing if necessary
  Future<bool> _ensureValidAccessToken() async {
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }

    final now = DateTime.now();
    final expiryWithBuffer = _tokenExpiry!.subtract(_expiryBuffer);

    // Token is still valid
    if (now.isBefore(expiryWithBuffer)) {
      return true;
    }

    // Token expired or expiring soon - refresh it
    logDebug('[TokenManager] Access token expired or expiring soon, refreshing');
    try {
      final storedRefreshToken = await _tokenStorage.getRefreshToken();
      if (storedRefreshToken == null) {
        logDebug('[TokenManager] No refresh token available');
        return false;
      }

      final credentials = await _auth0.api.renewCredentials(
        refreshToken: storedRefreshToken,
      );

      setAccessToken(credentials.accessToken);

      // Store new refresh token if provided
      if (credentials.refreshToken != null) {
        await _tokenStorage.saveRefreshToken(credentials.refreshToken!);
      }

      return true;
    } catch (e) {
      logDebug('[TokenManager] Failed to refresh token: $e');
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

      // Refresh tokens may not always be JWTs in Auth0
      // If it's not a JWT (3 parts), we'll skip validation and let the API handle it
      if (parts.length != 3) {
        logDebug('[TokenManager] Token is not a JWT, skipping audience validation');
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

      // If no audience claim exists, skip validation
      if (aud == null) {
        logDebug('[TokenManager] No audience claim in token');
        return true;
      }

      // Audience can be a string or array of strings
      if (aud is String) {
        final isValid = aud == AppConfig.authAudience;
        if (!isValid) {
          logDebug('[TokenManager] Audience mismatch: expected ${AppConfig.authAudience}, got $aud');
        }
        return isValid;
      } else if (aud is List) {
        final isValid = aud.contains(AppConfig.authAudience);
        if (!isValid) {
          logDebug('[TokenManager] Audience mismatch: expected ${AppConfig.authAudience} in $aud');
        }
        return isValid;
      }

      logDebug('[TokenManager] Unexpected audience type: ${aud.runtimeType}');
      return false;
    } catch (e) {
      logDebug('[TokenManager] Error validating token audience: $e');
      // On error, fail safely by rejecting the token
      return false;
    }
  }
}
