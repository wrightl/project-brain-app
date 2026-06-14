import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectbrain/helpers/app_themes.dart';

/// Service for managing application preferences
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Keys
  static const String _lastRouteKey = 'last_route_key';
  static const String _themeModeKey = 'theme_mode';

  /// Get the last visited route
  String? get lastRoute => _prefs.getString(_lastRouteKey);

  /// Get the selected theme mode id from [AppThemes].
  String get themeMode {
    final stored = _prefs.getString(_themeModeKey);
    if (stored == null) return AppThemes.defaultId;
    return AppThemes.isValid(stored) ? stored : AppThemes.defaultId;
  }

  /// Set the selected theme mode
  Future<bool> setThemeMode(String value) async {
    return await _prefs.setString(_themeModeKey, value);
  }

  /// Get a string value
  String? getString(String key) => _prefs.getString(key);

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

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

  /// Remove a key (e.g. user-scoped cache on logout).
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}
