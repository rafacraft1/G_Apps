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
      // PERBAIKAN: Ubah /absensi/riwayat menjadi /absen/riwayat agar cocok dengan Routes.php
      final response = await ApiClient().dio.get('/absen/riwayat');

      if (response.statusCode == 200 && response.data != null) {
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
      // PERBAIKAN: Ubah /absensi/riwayat menjadi /absen/riwayat
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
      if (e.response?.statusCode == 401) {
        // Ini yang memicu pesan "Sesi Habis" di HomeScreen jika rute salah/token ditolak
        throw 'sesi_habis';
      }
      return null;
    } catch (e) {
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
      String base64Foto = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      FormData formData = FormData.fromMap({
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'is_fake_gps': isMocked ? 1 : 0,
        'foto': base64Foto,
      });

      // PERBAIKAN: Ubah /absensi/ menjadi /absen/
      final response = await ApiClient().dio.post(
            '/absen/$tipeAbsen',
            data: formData,
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw response.data['message'] ?? 'Terjadi kesalahan sistem.';
      }
    } on DioException catch (e) {
      String pesanError = 'Gagal menghubungi server.';
      if (e.response?.data != null && e.response?.data is Map) {
        pesanError = e.response?.data['message'] ??
            e.response?.data['messages']?['error'] ??
            pesanError;
      }
      throw pesanError;
    } catch (e) {
      throw 'Terjadi kesalahan saat memproses absensi.';
    }
  }
}
