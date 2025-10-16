import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/models/user.dart';
import 'package:projectbrain/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  late final UserService userService;

  bool _isLoading = false;
  bool _onboardingComplete = false;
  User? _user;

  AuthProvider({required this.authService}) {
    userService = UserService(authService: authService);
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => authService.isLoggedIn;
  // String? get accessToken => authService.accessToken;
  Auth0User? get profile => authService.profile;
  User? get user => _user;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await authService.init();
    if (isLoggedIn) {
      await _fetchUserData();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.login();
      await _fetchUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _user = null;
    _onboardingComplete = false;
    notifyListeners();
  }

  Future<void> completeOnboarding(Map<String, dynamic> formData) async {
    await userService.completeOnboarding(formData);
    await _fetchUserData();
    notifyListeners();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await userService.getCurrentUser();
      _user = User.fromJson(data);
      _onboardingComplete = _user?.isOnboarded ?? false;
    } catch (e) {
      _user = null;
      _onboardingComplete = false;
    }
  }

  /// Manually refresh user data from the server
  Future<void> refreshUserData() async {
    await _fetchUserData();
    notifyListeners();
  }
}
