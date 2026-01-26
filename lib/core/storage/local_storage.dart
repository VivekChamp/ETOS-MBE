import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(); // Initialized in main
});

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static const String _keyServerUrl = 'server_url';
  static const String _keyUseHttps = 'use_https';
  static const String _keySessionId = 'session_id';

  Future<void> saveServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url);
  }

  String? getServerUrl() {
    return _prefs.getString(_keyServerUrl);
  }

  Future<void> saveUseHttps(bool value) async {
    await _prefs.setBool(_keyUseHttps, value);
  }

  bool getUseHttps() {
    // Default to true (HTTPS)
    return _prefs.getBool(_keyUseHttps) ?? true;
  }
}
