import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageHelper {
  static const _secureStorage = FlutterSecureStorage();

  static const _keyToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyBoundUser = 'bound_user';

  static const _keyName = 'user_name';
  static const _keyNis = 'user_nis';
  static const _keyFoto = 'user_foto';
  static const _keyKelas = 'user_kelas';

  /// Murni Secure Storage (Data Sensitif)
  static Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _secureStorage.write(key: _keyToken, value: access);
    await _secureStorage.write(key: _keyRefreshToken, value: refresh);
  }

  static Future<String?> getToken() async =>
      await _secureStorage.read(key: _keyToken);
  static Future<String?> getRefreshToken() async =>
      await _secureStorage.read(key: _keyRefreshToken);

  static Future<void> saveUserId(String id) async =>
      await _secureStorage.write(key: _keyUserId, value: id);
  static Future<String?> getUserId() async =>
      await _secureStorage.read(key: _keyUserId);

  static Future<void> setBoundUser(String nis) async =>
      await _secureStorage.write(key: _keyBoundUser, value: nis);
  static Future<String?> getBoundUser() async =>
      await _secureStorage.read(key: _keyBoundUser);
  static Future<void> clearDeviceBinding() async =>
      await _secureStorage.delete(key: _keyBoundUser);

  /// SharedPreferences (Data Non-Sensitif - Performa Tinggi)
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> saveUserNis(String nis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNis, nis);
  }

  static Future<String?> getUserNis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNis);
  }

  static Future<void> setFotoProfile(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFoto, url);
  }

  static Future<String?> getFotoProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFoto);
  }

  static Future<void> saveUserKelas(String kelas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyKelas, kelas);
  }

  static Future<String?> getUserKelas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyKelas);
  }

  /// Pembersihan Universal
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
