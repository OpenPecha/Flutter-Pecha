import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  Future<T?> get<T>(String key);
  Future<bool> set<T>(String key, T value);
  Future<bool> remove(String key);
  Future<bool> clear();
  Future<bool> containsKey(String key);
}

class SharedPreferencesService implements PreferencesService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<T?> get<T>(String key) async {
    final prefs = await _instance;
    return prefs.get(key) as T?;
  }

  @override
  Future<bool> set<T>(String key, T value) async {
    final prefs = await _instance;
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is bool) return prefs.setBool(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    throw UnsupportedError('Type ${T.toString()} not supported');
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _instance;
    return prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    final prefs = await _instance;
    return prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    final prefs = await _instance;
    return prefs.containsKey(key);
  }
}

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return SharedPreferencesService();
});