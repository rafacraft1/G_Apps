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

  Future<bool> login(String nis) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? boundUser = await SecureStorageHelper.getBoundUser();

      if (boundUser != null && boundUser.isNotEmpty && boundUser != nis) {
        throw 'HP ini telah dikunci untuk NIS ($boundUser). Anda tidak diizinkan login menggunakan perangkat ini!';
      }

      String deviceId = await _getDeviceId();
      debugPrint('Mencoba login dengan Device ID: $deviceId');

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Gagal mendapat FCM Token: $e');
      }

      // PERBAIKAN: Tambahkan parameter password (dikirim sama dengan NIS jika default)
      FormData formData = FormData.fromMap({
        'nis': nis,
        'password': nis, // <-- Wajib ada untuk lolos validasi CI4
        'device_id': deviceId,
        'fcm_token': fcmToken ?? '',
      });

      final response = await ApiClient().dio.post(
            '/auth/login',
            data: formData,
          );

      debugPrint('Respon Server CI4: ${response.data}');

      if (response.statusCode == 200 || response.data['status'] == 200) {
        var responseData = response.data['data'];

        String token = responseData['token'] ?? '';
        String nama = responseData['nama_siswa'] ??
            responseData['nama_lengkap'] ??
            'Siswa';
        String foto = responseData['foto_profil'] ?? responseData['foto'] ?? '';

        await SecureStorageHelper.saveToken(token);
        await SecureStorageHelper.saveUserName(nama);
        await SecureStorageHelper.saveUserNis(nis);

        if (foto.isNotEmpty) {
          await SecureStorageHelper.setFotoProfile(foto);
        }

        await SecureStorageHelper.setBoundUser(nis);

        return true;
      } else {
        throw response.data['message'] ?? 'Login gagal';
      }
    } on DioException catch (e) {
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
            '/profile/uploadFoto', // Sesuaikan endpoint dengan CI4
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

      if (response.statusCode == 200) {
        String urlBaru =
            response.data['data']['foto_url'] ?? response.data['foto_url'];
        await SecureStorageHelper.setFotoProfile(urlBaru);
        return urlBaru;
      } else {
        throw response.data['message'] ?? 'Gagal mengunggah foto.';
      }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Gagal menghubungi server.';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> ajukanResetDevice(String alasan) async {
    try {
      String? token = await SecureStorageHelper.getToken();

      // PERBAIKAN: Gunakan variabel token sebagai validasi untuk mencegah Warning Unused Variable
      // sekaligus memberikan proteksi sesi ekstra jika token di lokal sudah terhapus
      if (token == null) {
        throw 'Sesi Anda telah habis. Silakan login ulang.';
      }

      FormData formData = FormData.fromMap({'alasan': alasan});

      final response = await ApiClient().dio.post(
            '/auth/resetDevice', // Sesuaikan dengan CI4
            data: formData,
          );

      if (response.statusCode == 200) {
        await SecureStorageHelper.clearDeviceBinding();
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Gagal mengajukan reset device.';
    } catch (e) {
      throw 'Terjadi kesalahan sistem.';
    }
  }
}
