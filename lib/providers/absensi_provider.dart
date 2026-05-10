import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/api/api_client.dart';

class AbsensiProvider with ChangeNotifier {
  List<dynamic> _listRiwayat = [];
  List<dynamic> get listRiwayat => _listRiwayat;

  bool _isLoadingRiwayat = false;
  bool get isLoadingRiwayat => _isLoadingRiwayat;

  Future<void> fetchRiwayatAbsen() async {
    _isLoadingRiwayat = true;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get('/absen/riwayat');

      if (response.statusCode == 200 && response.data != null) {
        // Karena response JSON sudah berformat { status: 200, message: '...', data: [...] }
        _listRiwayat = response.data['data'] ?? [];
      } else {
        _listRiwayat = [];
      }
    } catch (e) {
      debugPrint('Gagal ambil daftar riwayat: $e');
      _listRiwayat = [];
    } finally {
      _isLoadingRiwayat = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> cekAbsenHariIni(String tanggal) async {
    try {
      final response = await ApiClient().dio.get('/absen/riwayat');

      if (response.statusCode == 200 && response.data != null) {
        List data = response.data['data'] ?? [];
        for (var item in data) {
          if (item['tanggal'] == tanggal) {
            return item;
          }
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Gagal cek riwayat hari ini: $e');
      if (e.response?.statusCode == 401) {
        throw 'sesi_habis';
      }
      return null;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  Future<bool> kirimAbsen({
    required File foto,
    required double lat,
    required double lon,
    required bool isMocked,
    required String tipeAbsen, // 'masuk' atau 'pulang'
  }) async {
    try {
      final filePath = foto.absolute.path;
      final extensionIndex = filePath.lastIndexOf('.');
      final outPath = "${filePath.substring(0, extensionIndex)}_compressed.jpg";

      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        foto.absolute.path,
        outPath,
        quality: 60,
        minWidth: 800,
        minHeight: 800,
      );

      File finalFile =
          compressedFile != null ? File(compressedFile.path) : foto;

      List<int> imageBytes = await finalFile.readAsBytes();
      String base64Foto = base64Encode(imageBytes);

      // KUNCI: Key Form Data harus sesuai dengan yang ditangkap di AbsensiApi.php
      FormData formData = FormData.fromMap({
        'lat': lat.toString(),
        'long': lon.toString(),
        'is_mock': isMocked ? 'true' : 'false',
        'foto': base64Foto,
      });

      final response = await ApiClient().dio.post(
            '/absen/$tipeAbsen',
            data: formData,
          );

      if (response.statusCode == 201 || // Status code Created
          response.statusCode == 200 ||
          response.data['status'] == 200 ||
          response.data['status'] == 'success') {
        return true;
      } else {
        throw response.data['message'] ?? 'Terjadi kesalahan sistem.';
      }
    } on DioException catch (e) {
      debugPrint('Error API Absen: ${e.response?.data}');

      String pesanError = 'Gagal menghubungi server.';
      if (e.response?.data != null && e.response?.data is Map) {
        // Ambil struktur error CI4
        pesanError = e.response?.data['message'] ??
            e.response?.data['messages']?['error'] ??
            pesanError;
      }
      throw pesanError;
    } catch (e) {
      debugPrint('Error Kompresi/Absen: $e');
      throw 'Terjadi kesalahan saat memproses absensi.';
    }
  }
}
