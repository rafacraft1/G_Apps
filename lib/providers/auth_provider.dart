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
        String brand = androidInfo.brand;
        String model = androidInfo.model;
        String osVersion = androidInfo.version.release;
        String androidId = androidInfo.id;

        return "${brand}_${model}_Android-${osVersion}_$androidId"
            .replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        String brand = 'Apple';
        String model = iosInfo.model;
        String osVersion = iosInfo.systemVersion;
        String idfv = iosInfo.identifierForVendor ?? 'unknown_id';

        return "${brand}_${model}_iOS-${osVersion}_$idfv".replaceAll(' ', '_');
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
        'password': nis,
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

        await SecureStorageHelper.saveTokens(
            access: accessToken, refresh: refreshToken);
        await SecureStorageHelper.saveUserId(idSiswa);
        await SecureStorageHelper.saveUserName(nama);
        await SecureStorageHelper.saveUserNis(nis);
        await SecureStorageHelper.saveUserKelas(kelas);

        if (foto.isNotEmpty) {
          await SecureStorageHelper.setFotoProfile(foto);
        }

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

  /// Membersihkan sesi perangkat secara lokal
  Future<bool> resetDeviceLokal() async {
    try {
      await SecureStorageHelper.clearAll();
      return true;
    } catch (e) {
      throw 'Gagal membersihkan cache perangkat lokal.';
    }
  }
}
