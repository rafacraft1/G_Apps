import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class AbsensiProvider with ChangeNotifier {
  List<dynamic> _listRiwayat = [];
  List<dynamic> get listRiwayat => _listRiwayat;

  bool _isLoadingRiwayat = false;
  bool get isLoadingRiwayat => _isLoadingRiwayat;

  static const String _cacheKey = 'riwayat_absen_cache';

  Future<void> fetchRiwayatAbsen() async {
    final prefs = await SharedPreferences.getInstance();

    String? cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      _listRiwayat = jsonDecode(cachedData);
      notifyListeners();
    } else {
      _isLoadingRiwayat = true;
      notifyListeners();
    }

    try {
      final response = await ApiClient().dio.get('/absen/riwayat');

      if (response.statusCode == 200 && response.data != null) {
        _listRiwayat = response.data['data'] ?? [];
        await prefs.setString(_cacheKey, jsonEncode(_listRiwayat));
      } else {
        if (cachedData == null) _listRiwayat = [];
      }
    } catch (e) {
      debugPrint('Gagal ambil daftar riwayat: $e');
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
      if (e.response?.statusCode == 401) {
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
    required String tipeAbsen,
  }) async {
    File? fileToCleanUp;

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

      if (compressedFile != null) fileToCleanUp = finalFile;

      FormData formData = FormData.fromMap({
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'is_fake_gps': isMocked ? 1 : 0,
        'foto': await MultipartFile.fromFile(finalFile.path,
            filename: 'absen_$tipeAbsen.jpg'),
      });

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
    } finally {
      if (fileToCleanUp != null && await fileToCleanUp.exists()) {
        await fileToCleanUp.delete();
      }
    }
  }
}
