import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api/api_client.dart';
import '../core/utils/secure_storage_helper.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Mengambil kombinasi Merek, Tipe, Versi OS, dan Secure ID pengganti IMEI
  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.brand}_${androidInfo.model}_Android-${androidInfo.version.release}_${androidInfo.id}"
            .replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return "Apple_${iosInfo.model}_iOS-${iosInfo.systemVersion}_${iosInfo.identifierForVendor ?? 'unknown_id'}"
            .replaceAll(' ', '_');
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan Device ID: $e');
    }
    return 'unknown_device';
  }

  /// Memproses otentikasi login
  Future<bool> login(String nis) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? boundUser = await SecureStorageHelper.getBoundUser();

      // Cek apakah HP ini sudah pernah dipakai oleh NIS lain
      if (boundUser != null && boundUser.isNotEmpty && boundUser != nis) {
        throw 'Perangkat ini telah terkunci untuk NIS ($boundUser). Hubungi Wali Kelas untuk melakukan Reset Device.';
      }

      String deviceId = await _getDeviceId();
      String? fcmToken;

      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Gagal mendapat FCM Token: $e');
      }

      FormData formData = FormData.fromMap({
        'nis': nis,
        'password': nis, // Default password menggunakan NIS
        'device_id': deviceId,
        'fcm_token': fcmToken ?? '',
      });

      final response = await ApiClient().dio.post(
            'auth/login',
            data: formData,
          );

      if (response.statusCode == 200 && response.data != null) {
        String accessToken = response.data['access_token'] ?? '';
        String refreshToken = response.data['refresh_token'] ?? '';
        var responseData = response.data['data'] ?? {};

        String idSiswa = responseData['id_siswa']?.toString() ?? '';
        String nama = responseData['nama_siswa'] ?? 'Siswa';
        String foto = responseData['foto_profil'] ?? '';
        String kelas = responseData['nama_kelas'] ?? 'Siswa Aktif';

        if (accessToken.isEmpty || refreshToken.isEmpty || idSiswa.isEmpty) {
          throw 'Server mengembalikan data yang tidak lengkap.';
        }

        // Simpan data sesi ke lokal
        await SecureStorageHelper.saveTokens(
            access: accessToken, refresh: refreshToken);
        await SecureStorageHelper.saveUserId(idSiswa);
        await SecureStorageHelper.saveUserName(nama);
        await SecureStorageHelper.saveUserNis(nis);
        await SecureStorageHelper.saveUserKelas(kelas);

        if (foto.isNotEmpty) {
          await SecureStorageHelper.setFotoProfile(foto);
        }

        // Kunci HP ini secara permanen untuk NIS yang berhasil login
        await SecureStorageHelper.setBoundUser(nis);

        return true;
      } else {
        throw 'Terjadi kesalahan sistem di server. Silakan hubungi admin.';
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'Gagal login, periksa NIS Anda.';
      }
      throw 'Gagal menghubungi server atau jaringan terputus.';
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Proses Logout yang terintegrasi (Hitamkan Token & Pertahankan Kunci Perangkat)
  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Beritahu server untuk memasukkan Token ke daftar Blacklist
      try {
        await ApiClient().dio.post('auth/logout');
      } catch (e) {
        debugPrint('Logout server gagal / token kedaluwarsa. Abaikan.');
      }

      // 2. Simpan sementara data pengunci HP (NIS) sebelum memori dibersihkan
      String? boundUser = await SecureStorageHelper.getBoundUser();

      // 3. Bersihkan memori sesi lokal
      await SecureStorageHelper.clearAll();

      // 4. Kembalikan PENGUNCI HP agar siswa lain tetap tidak bisa login di HP ini
      if (boundUser != null) {
        await SecureStorageHelper.setBoundUser(boundUser);
      }

      return true;
    } catch (e) {
      throw 'Terjadi kesalahan saat logout.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memproses unggah foto profil ke server
  Future<String> uploadFotoProfil(File fileFoto) async {
    try {
      String? token = await SecureStorageHelper.getToken();
      String? nis = await SecureStorageHelper.getUserNis();

      if (token == null || nis == null) {
        throw 'Sesi Anda telah habis. Silakan login ulang.';
      }

      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          fileFoto.path,
          filename: fileFoto.path.split('/').last,
        ),
      });

      final response = await ApiClient().dio.post(
            'profile/upload-foto',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

      if (response.statusCode == 200 && response.data != null) {
        String namaFoto = response.data['foto_profil'] ?? '';

        if (namaFoto.isEmpty) {
          throw 'Server gagal memproses foto.';
        }

        await SecureStorageHelper.setFotoProfile(namaFoto);
        return namaFoto;
      } else {
        throw 'Gagal mengunggah foto karena kesalahan server.';
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'Gagal menghubungi server.';
      }
      throw 'Koneksi ke server terputus.';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Membersihkan seluruh data (Digunakan khusus jika perangkat di-Reset Admin)
  Future<bool> resetDeviceLokal() async {
    try {
      await SecureStorageHelper
          .clearAll(); // Bersihkan semua memori termasuk pengunci
      return true;
    } catch (e) {
      throw 'Gagal membersihkan cache perangkat lokal.';
    }
  }
}
