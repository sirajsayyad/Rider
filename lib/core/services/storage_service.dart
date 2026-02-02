import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage Service for local data persistence
class StorageService {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;
  
  /// Initialize storage
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  // Regular storage methods (non-sensitive data)
  
  /// Get string value
  String? getString(String key) => _prefs.getString(key);
  
  /// Set string value
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  
  /// Get int value
  int? getInt(String key) => _prefs.getInt(key);
  
  /// Set int value
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  
  /// Get double value
  double? getDouble(String key) => _prefs.getDouble(key);
  
  /// Set double value
  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);
  
  /// Get bool value
  bool? getBool(String key) => _prefs.getBool(key);
  
  /// Set bool value
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  
  /// Get string list
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  
  /// Set string list
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  
  /// Remove a key
  Future<bool> remove(String key) => _prefs.remove(key);
  
  /// Clear all data
  Future<bool> clear() => _prefs.clear();
  
  /// Check if key exists
  bool containsKey(String key) => _prefs.containsKey(key);
  
  // Secure storage methods (for sensitive data)
  
  /// Get secure string
  Future<String?> getSecureString(String key) =>
      _secureStorage.read(key: key);
  
  /// Set secure string
  Future<void> setSecureString(String key, String value) =>
      _secureStorage.write(key: key, value: value);
  
  /// Delete secure string
  Future<void> deleteSecureString(String key) =>
      _secureStorage.delete(key: key);
  
  /// Clear all secure storage
  Future<void> clearSecureStorage() => _secureStorage.deleteAll();
  
  /// Check if secure key exists
  Future<bool> containsSecureKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }
}

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
