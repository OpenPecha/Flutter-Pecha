import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_storage_keys.dart';

abstract class LocalStorageService {
  // ========== USER DATA ==========
  Future<void> setUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> clearUserData();

  // ========== ONBOARDING ==========
  Future<void> setOnboardingCompleted(bool completed);
  Future<bool> getOnboardingCompleted();

  Future<T?> get<T>(String key);

  Future<bool> set<T>(String key, T value);

  Future<bool> remove(String key);

  Future<bool> clear();

  Future<bool> containsKey(String key);
}

class LocalStorageServiceImpl implements LocalStorageService {
  static SharedPreferences? _sharedPreferences;

  /// Gets the SharedPreferences instance, initializing it lazily if needed
  Future<SharedPreferences> get _prefs async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  LocalStorageServiceImpl();

  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {
    final userDataJson = json.encode(userData);
    final prefs = await _prefs;
    await prefs.setString(AppStorageKeys.userData, userDataJson);
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _prefs;
    final userDataJson = prefs.getString(AppStorageKeys.userData);
    if (userDataJson != null) {
      return json.decode(userDataJson) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> clearUserData() async {
    final prefs = await _prefs;
    await prefs.remove(AppStorageKeys.userData);
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _prefs;
    await prefs.setBool(AppStorageKeys.onboardingCompleted, completed);
  }

  @override
  Future<bool> getOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(AppStorageKeys.onboardingCompleted) ?? false;
  }

  @override
  Future<T?> get<T>(String key) async {
    final prefs = await _prefs;
    return prefs.get(key) as T?;
  }

  @override
  Future<bool> set<T>(String key, T value) async {
    final prefs = await _prefs;
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is bool) return prefs.setBool(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    throw UnsupportedError('Type ${T.toString()} not supported');
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    final prefs = await _prefs;
    return prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }
}

/// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageServiceImpl();
});
