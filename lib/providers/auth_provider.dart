import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- TAMBAHAN IMPORT FCM[cite: 8]
import '../core/api/api_client.dart';
import '../core/utils/secure_storage_helper.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.id}-${androidInfo.model}".replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan Device ID: $e');
    }
    return 'unknown_device';
  }

  // === FUNGSI LOGIN ===[cite: 8]
  Future<bool> login(String nis) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ====================================================
      // GEMBOK LOKAL: Cek apakah HP ini sudah punya pemilik?[cite: 8]
      // ====================================================
      String? boundUser = await SecureStorageHelper.getBoundUser();

      if (boundUser != null && boundUser.isNotEmpty && boundUser != nis) {
        // Jika yang login bukan pemilik aslinya, TOLAK LANGSUNG![cite: 8]
        throw 'HP ini telah dikunci untuk NIS ($boundUser). Anda tidak diizinkan login menggunakan perangkat ini!';
      }

      // Jika lolos (pemilik asli atau login pertama kali), lanjut ke Server CI4[cite: 8]
      String deviceId = await _getDeviceId();
      debugPrint('Mencoba login dengan Device ID: $deviceId');

      // === Ambil FCM Token dari Google ===[cite: 8]
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token Berhasil didapat: $fcmToken');
      } catch (e) {
        debugPrint('Gagal mendapat FCM Token: $e');
      }

      // === SISIPKAN fcm_token KE FORM DATA ===[cite: 8]
      FormData formData = FormData.fromMap({
        'nis': nis,
        'device_id': deviceId,
        'fcm_token': fcmToken ?? '', // <-- Kirim ke CI4[cite: 8]
      });

      final response = await ApiClient().dio.post(
            '/auth/login',
            data: formData,
          );

      debugPrint('Respon Server CI4: ${response.data}');

      if (response.statusCode == 200) {
        // Ambil data dari dalam bungkusan 'data' sesuai struktur JSON CI4[cite: 8]
        var responseData = response.data['data'];

        String token = responseData['token'] ?? 'token_sementara';
        String nama = responseData['nama_lengkap'] ?? 'Siswa';
        // Ambil foto jika backend CI4 mengirimkannya saat login
        String foto = responseData['foto'] ?? '';

        // SIMPAN SEMUA DATA KE LOKAL
        await SecureStorageHelper.saveToken(token);
        await SecureStorageHelper.saveUserName(nama);
        await SecureStorageHelper.saveUserNis(nis); // <-- Simpan NIS

        if (foto.isNotEmpty) {
          // Asumsi CI4 mengembalikan Full URL, atau simpan apa adanya
          await SecureStorageHelper.setFotoProfile(foto);
        }

        // ====================================================
        // KUNCI HP INI SECARA PERMANEN UNTUK NIS TERSEBUT[cite: 8]
        // ====================================================
        await SecureStorageHelper.setBoundUser(nis);

        return true;
      } else {
        throw response.data['message'] ?? 'Login gagal';
      }
    } on DioException catch (e) {
      debugPrint('Error API Login: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data['messages'] != null) {
        throw e.response?.data['messages']['error'] ?? 'Gagal login';
      }
      throw e.response?.data['message'] ?? 'Gagal menghubungi server.';
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === FUNGSI BARU: UPLOAD FOTO PROFIL ===
  Future<String> uploadFotoProfil(File fileFoto) async {
    try {
      String? token = await SecureStorageHelper.getToken();
      String? nis = await SecureStorageHelper.getUserNis();

      if (token == null || nis == null) {
        throw 'Sesi Anda telah habis atau data tidak lengkap. Silakan login ulang.';
      }

      // Bungkus NIS dan File Gambar ke dalam FormData
      FormData formData = FormData.fromMap({
        'nis': nis,
        'foto': await MultipartFile.fromFile(
          fileFoto.path,
          filename: fileFoto.path.split('/').last,
        ),
      });

      // Tembak API CI4
      final response = await ApiClient().dio.post(
            '/profile/upload-foto',
            data: formData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'multipart/form-data', // Wajib untuk kirim file
              },
            ),
          );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        String urlBaru = response.data['foto_url'];

        // Simpan URL baru ke penyimpanan lokal HP
        await SecureStorageHelper.setFotoProfile(urlBaru);

        return urlBaru;
      } else {
        throw response.data['message'] ?? 'Gagal mengunggah foto.';
      }
    } on DioException catch (e) {
      debugPrint('Error API Upload Foto: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Gagal menghubungi server.';
    } catch (e) {
      throw e.toString();
    }
  }

  // === FUNGSI RESET DEVICE ===[cite: 8]
  Future<bool> ajukanResetDevice(String alasan) async {
    try {
      String? token = await SecureStorageHelper.getToken();

      FormData formData = FormData.fromMap({'alasan': alasan});

      final response = await ApiClient().dio.post(
            '/auth/request-reset-device',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

      if (response.statusCode == 200) {
        // Jika reset disetujui, kita bisa membuka kunci lokal HP ini[cite: 8]
        await SecureStorageHelper.clearDeviceBinding();
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Error Reset Device: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data['messages'] != null) {
        throw e.response?.data['messages']['error'] ?? 'Gagal mengajukan reset';
      }
      throw e.response?.data['message'] ?? 'Gagal mengajukan reset device.';
    } catch (e) {
      throw 'Terjadi kesalahan sistem.';
    }
  }
}
