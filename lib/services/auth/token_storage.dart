import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Service responsible for securely storing and retrieving authentication tokens
class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  // Android: flutter_secure_storage v10 encrypts the backing store by default
  // (the old encryptedSharedPreferences flag is deprecated and ignored), so no
  // Android-specific options are needed. iOS: keep the refresh token in the
  // keychain, available after first unlock but never synced to iCloud.
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              iOptions: _iosOptions,
            );

  /// Store a refresh token securely
  Future<void> saveRefreshToken(String refreshToken) async {
    logDebug('[TokenStorage] Saving refresh token');
    await _secureStorage.write(
      key: AppConfig.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Retrieve the stored refresh token
  Future<String?> getRefreshToken() async {
    logDebug('[TokenStorage] Retrieving refresh token');
    return await _secureStorage.read(key: AppConfig.refreshTokenKey);
  }

  /// Delete the stored refresh token
  Future<void> deleteRefreshToken() async {
    logDebug('[TokenStorage] Deleting refresh token');
    await _secureStorage.delete(key: AppConfig.refreshTokenKey);
  }

  /// Clear all stored tokens
  Future<void> clearAll() async {
    logDebug('[TokenStorage] Clearing all tokens');
    await deleteRefreshToken();
  }
}
