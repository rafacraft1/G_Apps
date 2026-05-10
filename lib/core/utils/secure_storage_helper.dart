import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyName = 'user_name';
  static const _keyNis = 'user_nis'; // <-- KUNCI BARU UNTUK NIS
  static const _keyFoto = 'user_foto'; // <-- KUNCI BARU UNTUK FOTO
  static const _keyBoundUser = 'bound_user'; // <-- KUNCI PERMANEN HP[cite: 7]

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: _keyName, value: name);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyName);
  }

  // === FUNGSI BARU: Simpan & Ambil NIS ===
  static Future<void> saveUserNis(String nis) async {
    await _storage.write(key: _keyNis, value: nis);
  }

  static Future<String?> getUserNis() async {
    return await _storage.read(key: _keyNis);
  }

  // === FUNGSI BARU: Simpan & Ambil Foto ===
  static Future<void> setFotoProfile(String url) async {
    await _storage.write(key: _keyFoto, value: url);
  }

  static Future<String?> getFotoProfile() async {
    return await _storage.read(key: _keyFoto);
  }

  // === DEVICE BINDING LOKAL ===[cite: 7]
  static Future<void> setBoundUser(String nis) async {
    await _storage.write(key: _keyBoundUser, value: nis);
  }

  static Future<String?> getBoundUser() async {
    return await _storage.read(key: _keyBoundUser);
  }

  static Future<void> clearDeviceBinding() async {
    await _storage.delete(key: _keyBoundUser);
  }

  // === FUNGSI LOGOUT (HANYA HAPUS SESI) ===[cite: 7]
  static Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _keyNis); // Hapus sesi NIS
    await _storage.delete(key: _keyFoto); // Hapus sesi Foto
    // CATATAN: _keyBoundUser SENGAJA TIDAK DIHAPUS agar HP tetap terkunci[cite: 7]
  }
}
