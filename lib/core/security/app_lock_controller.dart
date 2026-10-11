import 'package:flutter/widgets.dart';

/// Hides app content while the app is not in the foreground (so the OS
/// app-switcher snapshot shows nothing) and, when biometric unlock is on,
/// requires it again after the app has been in the background for
/// [relockAfter].
///
/// The session stays in memory while locked; unlocking does not log in again.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required bool Function() isLockEnabled,
    required Future<bool> Function() authenticate,
    this.relockAfter = const Duration(minutes: 1),
    DateTime Function()? now,
  })  : _isLockEnabled = isLockEnabled,
        _authenticate = authenticate,
        _now = now ?? DateTime.now;

  final bool Function() _isLockEnabled;
  final Future<bool> Function() _authenticate;
  final DateTime Function() _now;
  final Duration relockAfter;

  bool _obscured = false;
  bool _locked = false;
  bool _unlocking = false;
  DateTime? _backgroundedAt;

  /// True while the app is inactive or backgrounded.
  bool get isObscured => _obscured;

  /// True when the user must authenticate before seeing content again.
  bool get isLocked => _locked;

  bool get isUnlocking => _unlocking;

  void handleLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Also fires for the Face ID sheet and system dialogs, so it hides
        // content but does not start the re-lock timer.
        _obscured = true;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _obscured = true;
        _backgroundedAt ??= _now();
      case AppLifecycleState.resumed:
        _obscured = false;
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt != null &&
            _isLockEnabled() &&
            _now().difference(backgroundedAt) >= relockAfter) {
          _locked = true;
        }
      case AppLifecycleState.detached:
        return;
    }
    notifyListeners();
  }

  /// Prompts for biometrics / device passcode and unlocks on success.
  Future<void> unlock() async {
    if (_unlocking || !_locked) return;
    _unlocking = true;
    notifyListeners();
    try {
      if (await _authenticate()) {
        _locked = false;
      }
    } finally {
      _unlocking = false;
      notifyListeners();
    }
  }
}
