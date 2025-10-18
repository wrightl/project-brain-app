import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Service responsible for securely storing and retrieving authentication tokens
class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Store a refresh token securely
  Future<void> saveRefreshToken(String refreshToken) async {
    debugPrint('[TokenStorage] Saving refresh token');
    await _secureStorage.write(
      key: AppConfig.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Retrieve the stored refresh token
  Future<String?> getRefreshToken() async {
    debugPrint('[TokenStorage] Retrieving refresh token');
    return await _secureStorage.read(key: AppConfig.refreshTokenKey);
  }

  /// Delete the stored refresh token
  Future<void> deleteRefreshToken() async {
    debugPrint('[TokenStorage] Deleting refresh token');
    await _secureStorage.delete(key: AppConfig.refreshTokenKey);
  }

  /// Clear all stored tokens
  Future<void> clearAll() async {
    debugPrint('[TokenStorage] Clearing all tokens');
    await deleteRefreshToken();
  }
}
