import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SharedPreferencesStorage {
  static Future<String?> setValue<T>(String key, T value) async {
    /// Set the channel name to the app bundle id
    const platformChannel = MethodChannel('com.dotdash.projectbrain/storage');

    try {
      /// Invoke the method to save the preferences in the native side
      final result = await platformChannel.invokeMethod('savePreferences', {
        'key': key,
        'value': value,
      });

      return result;
    } catch (err) {
      debugPrint('Error $err');
      return null;
    }
  }

  /// Set a boolean value in shared preferences
  static Future<String?> setBool(String key, bool value) async {
    const platformChannel = MethodChannel('com.dotdash.projectbrain/storage');

    try {
      final result = await platformChannel.invokeMethod('savePreferences', {
        'key': key,
        'value': value,
      });

      return result;
    } catch (err) {
      debugPrint('Error setting bool: $err');
      return null;
    }
  }

  /// Get a string value from shared preferences
  static Future<String?> getString(String key) async {
    const platformChannel = MethodChannel('com.dotdash.projectbrain/storage');

    try {
      final result = await platformChannel.invokeMethod('getPreferences', {
        'key': key,
        'type': 'string',
      });

      return result as String?;
    } catch (err) {
      debugPrint('Error getting string: $err');
      return null;
    }
  }

  /// Get a boolean value from shared preferences
  static Future<bool?> getBool(String key) async {
    const platformChannel = MethodChannel('com.dotdash.projectbrain/storage');

    try {
      final result = await platformChannel.invokeMethod('getPreferences', {
        'key': key,
        'type': 'bool',
      });

      if (result == null) return null;
      if (result is bool) return result;
      if (result is String) {
        return result.toLowerCase() == 'true';
      }
      return null;
    } catch (err) {
      debugPrint('Error getting bool: $err');
      return null;
    }
  }
}
