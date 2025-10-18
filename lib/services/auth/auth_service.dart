import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';
import 'package:projectbrain/services/auth/token_manager.dart';
import 'package:projectbrain/services/auth/token_storage.dart';
import 'package:projectbrain/services/auth/user_profile_service.dart';

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
    debugPrint('[AuthService] Initializing...');

    try {
      final storedRefreshToken = await _tokenStorage.getRefreshToken();
      if (storedRefreshToken == null) {
        debugPrint('[AuthService] No stored refresh token found');
        return false;
      }

      debugPrint('[AuthService] Attempting to refresh session');
      final credentials = await _oauthService.refreshCredentials(storedRefreshToken);

      // Validate the audience of the new access token
      final isValidAudience = await _tokenManager.validateTokenAudience(credentials.accessToken);
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
    debugPrint('[AuthService] Starting login');
    final credentials = await _oauthService.login();
    await _setLocalVariables(credentials);
    debugPrint('[AuthService] Login complete');
  }

  /// Log out the current user and clear all stored credentials
  Future<void> logout() async {
    debugPrint('[AuthService] Logging out');

    // Perform Auth0 logout to clear SSO session
    try {
      await _oauthService.logout();
    } catch (e) {
      // Log but don't fail - we still want to clear local session
      debugPrint('[AuthService] Error during remote logout: $e');
    }

    await _clearSession();
    debugPrint('[AuthService] Logout complete');
  }

  /// Get a valid access token, refreshing if necessary
  ///
  /// Throws [AuthException] if no valid token is available
  Future<String> getAccessToken() async {
    return await _tokenManager.getAccessToken();
  }

  /// Store authentication credentials and fetch user profile
  Future<void> _setLocalVariables(Credentials credentials) async {
    if (credentials.accessToken.isEmpty) {
      throw AuthException('Invalid credentials - missing access token');
    }

    _tokenManager.setAccessToken(credentials.accessToken);
    _profile = await _userProfileService.getUserProfile(credentials.accessToken);

    // Store refresh token securely if available
    if (credentials.refreshToken != null) {
      await _tokenStorage.saveRefreshToken(credentials.refreshToken!);
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
