import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';

/// Device biometric / device-credential unlock used before restoring Auth0 credentials.
class BiometricUnlockService {
  final LocalAuthentication _localAuth;

  BiometricUnlockService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Whether this device can use biometrics or device credentials for unlock.
  Future<bool> isSupported() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (e) {
      logWarning('[BiometricUnlockService] isSupported failed', e);
      return false;
    }
  }

  /// Human-readable label for the primary unlock button (Face ID, fingerprint, etc.).
  Future<String> unlockLabel() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        return Platform.isIOS ? 'Unlock with Face ID' : 'Unlock with Face';
      }
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return Platform.isIOS
            ? 'Unlock with Touch ID'
            : 'Unlock with fingerprint';
      }
    } catch (_) {
      // Fall through to generic label.
    }
    return 'Unlock with biometrics';
  }

  /// Prompt for biometric / device credential authentication.
  ///
  /// Returns true when the user succeeds. Throws [AuthException] when the user
  /// cancels or authentication fails.
  Future<bool> authenticate({
    String reason = 'Unlock Project Brain',
  }) async {
    try {
      final supported = await isSupported();
      if (!supported) {
        throw AuthException('Biometric authentication is not available');
      }

      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
      if (!ok) {
        throw AuthException('Biometric authentication failed');
      }
      return true;
    } on AuthException {
      rethrow;
    } on PlatformException catch (e) {
      logWarning('[BiometricUnlockService] authenticate platform error', e);
      throw AuthException(
        'Biometric authentication failed: ${e.message ?? e.code}',
        e,
      );
    } catch (e, stackTrace) {
      logWarning('[BiometricUnlockService] authenticate failed', e);
      throw AuthException(
        'Biometric authentication failed',
        e,
        stackTrace,
      );
    }
  }
}
