import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:projectbrain/helpers/constants.dart';
import 'package:projectbrain/models/auth0_id_token.dart';
import 'package:projectbrain/models/auth0_user.dart';

/// Exception thrown when authentication operations fail
class AuthException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AuthException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'AuthException: $message';
}

/// Service responsible for handling Auth0 authentication flows
class AuthService extends ChangeNotifier {
  final Auth0 _auth0;
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  Auth0User? _profile;
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Token expiry buffer - refresh tokens 5 minutes before they expire
  static const _expiryBuffer = Duration(minutes: 5);

  /// Whether the user is currently authenticated
  bool get isLoggedIn => _profile != null;

  /// The authenticated user's profile
  Auth0User? get profile => _profile;

  /// Constructor with dependency injection for testability
  AuthService({
    Auth0? auth0,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _auth0 = auth0 ?? Auth0(AUTH_DOMAIN, AUTH_CLIENT_ID),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  /// Initialize the auth service and attempt to restore previous session
  ///
  /// Returns true if a valid session was restored, false otherwise
  Future<bool> init() async {
    debugPrint('[AuthService] Initializing...');

    try {
      final storedRefreshToken =
          await _secureStorage.read(key: REFRESH_TOKEN_KEY);
      if (storedRefreshToken == null) {
        debugPrint('[AuthService] No stored refresh token found');
        return false;
      }

      debugPrint('[AuthService] Attempting to refresh session');
      final credentials = await _auth0.api.renewCredentials(
        refreshToken: storedRefreshToken,
      );

      // Validate the audience of the new access token
      final isValidAudience =
          await _validateTokenAudience(credentials.accessToken);
      if (!isValidAudience) {
        debugPrint('[AuthService] Invalid token audience, clearing session');
        await _clearSession();
        return false;
      }

      await _setLocalVariables(credentials);
      debugPrint('[AuthService] Session restored successfully');
      return true;
    } on ApiException catch (e) {
      debugPrint('[AuthService] API error during init: ${e.message}');
      await _clearSession();
      return false;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Unexpected error during init: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      await _clearSession();
      return false;
    }
  }

  /// Initiate the login flow
  ///
  /// Throws [AuthException] if login fails
  Future<void> login() async {
    try {
      debugPrint('[AuthService] Starting login flow');
      final credentials = await _auth0.webAuthentication().login(
            useHTTPS: true,
            audience: AUTH_AUDIENCE,
            scopes: {'openid', 'profile', 'offline_access', 'email'},
            redirectUrl: AUTH_REDIRECT_URI,
          );

      await _setLocalVariables(credentials);
      debugPrint('[AuthService] Login successful');
    } on WebAuthenticationException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        debugPrint('[AuthService] User cancelled login');
        throw AuthException('Login cancelled by user', e);
      }
      debugPrint('[AuthService] Web authentication error: ${e.message}');
      throw AuthException('Authentication failed: ${e.message}', e);
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Platform error during login: ${e.message}');
      throw AuthException('Platform error: ${e.message ?? "Unknown error"}', e);
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Unexpected error during login: $e');
      throw AuthException('Unexpected error during login', e, stackTrace);
    }
  }

  /// Log out the current user and clear all stored credentials
  Future<void> logout() async {
    try {
      debugPrint('[AuthService] Logging out');

      // Perform Auth0 logout to clear SSO session
      try {
        await _auth0.webAuthentication().logout(
              returnTo: AUTH_REDIRECT_URI,
            );
      } catch (e) {
        // Log but don't fail - we still want to clear local session
        debugPrint('[AuthService] Error during remote logout: $e');
      }

      await _clearSession();
      debugPrint('[AuthService] Logout complete');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Error during logout: $e');
      // Still clear local session even if remote logout fails
      await _clearSession();
      throw AuthException('Error during logout', e, stackTrace);
    }
  }

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

  /// Fetch user profile information from Auth0
  Future<Auth0User> getUserDetails(String accessToken) async {
    try {
      final url = Uri.https(AUTH_DOMAIN, '/userinfo');

      final response = await _httpClient.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return Auth0User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized - invalid access token');
      } else {
        throw AuthException(
          'Failed to get user details (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to fetch user details', e);
    }
  }

  /// Store authentication credentials and fetch user profile
  Future<void> _setLocalVariables(Credentials credentials) async {
    if (credentials.accessToken.isEmpty) {
      throw AuthException('Invalid credentials - missing access token');
    }

    _accessToken = credentials.accessToken;
    _tokenExpiry = _extractTokenExpiry(_accessToken!);
    _profile = await getUserDetails(credentials.accessToken);

    // Store refresh token securely if available
    if (credentials.refreshToken != null) {
      await _secureStorage.write(
        key: REFRESH_TOKEN_KEY,
        value: credentials.refreshToken,
      );
    }

    notifyListeners();
  }

  /// Clear all authentication data
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: REFRESH_TOKEN_KEY);
    _profile = null;
    _accessToken = null;
    _tokenExpiry = null;
    notifyListeners();
  }

  /// Validate that the refresh token's audience matches the expected audience
  Future<bool> _validateTokenAudience(String accessToken) async {
    try {
      final parts = accessToken.split('.');

      // Refresh tokens may not always be JWTs in Auth0
      // If it's not a JWT (3 parts), we'll skip validation and let the API handle it
      if (parts.length != 3) {
        debugPrint(
            '[AuthService] Refresh token is not a JWT, skipping audience validation');
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
        debugPrint('[AuthService] No audience claim in refresh token');
        return true;
      }

      // Audience can be a string or array of strings
      if (aud is String) {
        final isValid = aud == AUTH_AUDIENCE;
        if (!isValid) {
          debugPrint(
              '[AuthService] Audience mismatch: expected $AUTH_AUDIENCE, got $aud');
        }
        return isValid;
      } else if (aud is List) {
        final isValid = aud.contains(AUTH_AUDIENCE);
        if (!isValid) {
          debugPrint(
              '[AuthService] Audience mismatch: expected $AUTH_AUDIENCE in $aud');
        }
        return isValid;
      }

      debugPrint('[AuthService] Unexpected audience type: ${aud.runtimeType}');
      return false;
    } catch (e) {
      debugPrint('[AuthService] Error validating refresh token audience: $e');
      // On error, fail safely by rejecting the token
      return false;
    }
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
    debugPrint(
        '[AuthService] Access token expired or expiring soon, refreshing');
    try {
      final storedRefreshToken =
          await _secureStorage.read(key: REFRESH_TOKEN_KEY);
      if (storedRefreshToken == null) {
        debugPrint('[AuthService] No refresh token available');
        return false;
      }

      final credentials = await _auth0.api.renewCredentials(
        refreshToken: storedRefreshToken,
      );

      await _setLocalVariables(credentials);
      return true;
    } catch (e) {
      debugPrint('[AuthService] Failed to refresh token: $e');
      await _clearSession();
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
      debugPrint('[AuthService] Error extracting token expiry: $e');
      return null;
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
