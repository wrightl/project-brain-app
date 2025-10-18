import 'package:flutter/material.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  late final UserService userService;

  bool _isLoading = false;
  bool _onboardingComplete = false;
  User? _user;
  String? _errorMessage;

  AuthProvider({required this.authService}) {
    userService = UserService(authService: authService);
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => authService.isLoggedIn;
  Auth0User? get profile => authService.profile;
  User? get user => _user;
  bool get onboardingComplete => _onboardingComplete;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.init();
      if (isLoggedIn) {
        await _fetchUserData();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error during init: $e');
      _errorMessage = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.login();
      await _fetchUserData();
    } catch (e) {
      debugPrint('[AuthProvider] Error during login: $e');
      _errorMessage = e.toString().replaceAll('AuthException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    try {
      await authService.logout();
      _user = null;
      _onboardingComplete = false;
    } catch (e) {
      debugPrint('[AuthProvider] Error during logout: $e');
      _errorMessage = 'Failed to logout';
    } finally {
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> formData) async {
    _errorMessage = null;
    try {
      await userService.completeOnboarding(formData);
      await _fetchUserData();
    } catch (e) {
      debugPrint('[AuthProvider] Error during onboarding: $e');
      _errorMessage = 'Failed to complete onboarding';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await userService.getCurrentUser();
      _user = User.fromJson(data);
      _onboardingComplete = _user?.isOnboarded ?? false;
    } catch (e) {
      debugPrint('[AuthProvider] Error fetching user data: $e');
      _user = null;
      _onboardingComplete = false;
      _errorMessage = 'Failed to fetch user data';
    }
  }

  /// Manually refresh user data from the server
  Future<void> refreshUserData() async {
    _errorMessage = null;
    try {
      await _fetchUserData();
    } catch (e) {
      debugPrint('[AuthProvider] Error refreshing user data: $e');
      _errorMessage = 'Failed to refresh user data';
    } finally {
      notifyListeners();
    }
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
