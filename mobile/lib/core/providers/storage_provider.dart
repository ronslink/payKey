import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage provider with shared_preferences for persistent storage
final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main.dart');
});

/// Storage service for persistent key-value storage
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Read a value from storage
  String? read(String key) {
    return _prefs.getString(key);
  }

  /// Write a value to storage
  Future<bool> write(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Delete a value from storage
  Future<bool> delete(String key) async {
    return await _prefs.remove(key);
  }

  /// Clear all storage
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}