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
}
