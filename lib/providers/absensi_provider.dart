import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/utils/image_helper.dart';

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
      final response = await ApiClient().dio.get(ApiEndpoints.riwayatAbsen);

      if (response.statusCode == 200 && response.data != null) {
        _listRiwayat = response.data['data'] ?? [];
        await prefs.setString(_cacheKey, jsonEncode(_listRiwayat));
      } else {
        if (cachedData == null) {
          _listRiwayat = [];
        }
      }
    } catch (_) {
    } finally {
      _isLoadingRiwayat = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> cekAbsenHariIni(String tanggal) async {
    if (_listRiwayat.isEmpty) {
      await fetchRiwayatAbsen();
    }

    for (var item in _listRiwayat) {
      if (item['tanggal'] == tanggal) {
        return item;
      }
    }

    return null;
  }

  Future<bool> kirimAbsen({
    required File foto,
    required double lat,
    required double lon,
    required bool isMocked,
    required double accuracy,
    required int deviceTimestamp,
    required String tipeAbsen,
  }) async {
    File? fileToCleanUp;

    try {
      File? compressedFile = await ImageHelper.compressImage(foto);

      File finalFile = compressedFile ?? foto;
      if (compressedFile != null) {
        fileToCleanUp = finalFile;
      }

      FormData formData = FormData.fromMap({
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'is_mock': isMocked ? 1 : 0,
        'accuracy': accuracy.toString(),
        'device_timestamp': deviceTimestamp.toString(),
        'foto': await MultipartFile.fromFile(finalFile.path,
            filename: 'absen_$tipeAbsen.jpg'),
      });

      final response = await ApiClient().dio.post(
            ApiEndpoints.absen(tipeAbsen),
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
    } catch (_) {
      throw 'Terjadi kesalahan saat memproses absensi.';
    } finally {
      if (fileToCleanUp != null && await fileToCleanUp.exists()) {
        await fileToCleanUp.delete();
      }
    }
  }
}
