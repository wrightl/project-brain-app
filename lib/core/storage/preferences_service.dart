import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing application preferences
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Keys
  static const String _lastRouteKey = 'last_route_key';

  /// Get the last visited route
  String? get lastRoute => _prefs.getString(_lastRouteKey);

  /// Set the last visited route
  Future<bool> setLastRoute(String route) async {
    return await _prefs.setString(_lastRouteKey, route);
  }

  /// Clear the last route
  Future<bool> clearLastRoute() async {
    return await _prefs.remove(_lastRouteKey);
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Get a boolean value
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Set a boolean value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
}
