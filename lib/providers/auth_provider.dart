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

  /// Mengambil Device ID berdasarkan platform OS
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

  /// Memproses otentikasi login
  Future<bool> login(String nis) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? boundUser = await SecureStorageHelper.getBoundUser();

      if (boundUser != null && boundUser.isNotEmpty && boundUser != nis) {
        throw 'HP ini telah dikunci untuk NIS ($boundUser). Anda tidak diizinkan login menggunakan perangkat ini!';
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
            '/auth/login',
            data: formData,
          );

      bool isSuccess = response.statusCode == 200;
      if (!isSuccess && response.data is Map) {
        isSuccess = response.data['status'] == 200;
      }

      if (isSuccess) {
        if (response.data is! Map) {
          throw 'Format respon dari server tidak valid (bukan JSON).';
        }

        String accessToken = response.data['access_token'] ?? '';
        String refreshToken = response.data['refresh_token'] ?? '';
        var responseData = response.data['data'] ?? {};

        String idSiswa = responseData['id_siswa']?.toString() ??
            responseData['id']?.toString() ??
            '';

        String nama = responseData['nama_siswa'] ??
            responseData['nama_lengkap'] ??
            'Siswa';

        String foto = responseData['foto_profil'] ?? responseData['foto'] ?? '';

        String kelas = responseData['nama_kelas'] ??
            responseData['kelas'] ??
            'Siswa Aktif';

        if (accessToken.isEmpty || refreshToken.isEmpty) {
          throw 'Server tidak mengembalikan token keamanan.';
        }

        if (idSiswa.isEmpty) {
          throw 'Server tidak mengembalikan ID Siswa.';
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
        if (response.data is Map) {
          throw response.data['message'] ?? 'Login gagal';
        } else {
          throw 'Terjadi kesalahan sistem di server. Silakan hubungi admin.';
        }
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        if (e.response?.data['messages'] != null) {
          throw e.response?.data['messages']['error'] ?? 'Gagal login';
        }
        throw e.response?.data['message'] ?? 'Gagal menghubungi server.';
      }
      throw 'Gagal menghubungi server atau jaringan terputus.';
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memproses unggah foto profil
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
            '/profile/upload-foto',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

      if (response.statusCode == 200) {
        if (response.data is! Map) throw 'Format data tidak valid.';

        String namaFoto = response.data['foto_profil'] ?? '';

        if (namaFoto.isEmpty) {
          throw 'Server tidak mengembalikan nama foto.';
        }

        await SecureStorageHelper.setFotoProfile(namaFoto);
        return namaFoto;
      } else {
        if (response.data is Map) {
          throw response.data['message'] ?? 'Gagal mengunggah foto.';
        }
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

  /// Memproses pengajuan reset device
  Future<bool> ajukanResetDevice(String alasan) async {
    try {
      String? token = await SecureStorageHelper.getToken();

      if (token == null) {
        throw 'Sesi Anda telah habis. Silakan login ulang.';
      }

      FormData formData = FormData.fromMap({'alasan': alasan});

      final response = await ApiClient().dio.post(
            '/auth/resetDevice',
            data: formData,
          );

      if (response.statusCode == 200) {
        await SecureStorageHelper.clearDeviceBinding();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'Gagal mengajukan reset device.';
      }
      throw 'Terjadi kesalahan sistem pada server.';
    } catch (e) {
      throw 'Terjadi kesalahan sistem.';
    }
  }
}
