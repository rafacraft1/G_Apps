import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class IzinProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _listRiwayat = [];
  List<dynamic> get listRiwayat => _listRiwayat;

  static const String _cacheKey = 'riwayat_izin_cache';

  /// Mengajukan izin dengan kompresi gambar otomatis agar lolos batas 2MB Server
  Future<bool> ajukanIzin({
    required String tanggalMulai,
    required String tanggalSelesai,
    required String jenis,
    required String alasan,
    required File buktiFoto,
  }) async {
    _isLoading = true;
    notifyListeners();

    File? fileToCleanUp;

    try {
      final filePath = buktiFoto.absolute.path;
      final extensionIndex = filePath.lastIndexOf('.');
      final outPath =
          "${filePath.substring(0, extensionIndex)}_compressed_izin.jpg";

      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        buktiFoto.absolute.path,
        outPath,
        quality: 50,
        minWidth: 800,
        minHeight: 800,
      );

      File finalFile =
          compressedFile != null ? File(compressedFile.path) : buktiFoto;
      if (compressedFile != null) fileToCleanUp = finalFile;

      String fileName = finalFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'jenis': jenis,
        'alasan': alasan,
        'bukti_foto': await MultipartFile.fromFile(
          finalFile.path,
          filename: fileName,
        ),
      });

      final response = await ApiClient().dio.post(
            '/izin/ajukan',
            data: formData,
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchRiwayatIzin(forceRefresh: true);
        return true;
      } else {
        throw response.data['message'] ?? 'Gagal mengajukan izin.';
      }
    } on DioException catch (e) {
      String pesanError = 'Gagal menghubungi server.';
      if (e.response?.data != null && e.response?.data is Map) {
        if (e.response?.data['messages'] != null) {
          final errors = e.response?.data['messages'];
          pesanError = (errors is Map)
              ? errors.values.first.toString()
              : errors.toString();
        } else {
          pesanError = e.response?.data['message'] ?? pesanError;
        }
      }
      throw pesanError;
    } catch (e) {
      throw 'Terjadi kesalahan sistem.';
    } finally {
      if (fileToCleanUp != null && await fileToCleanUp.exists()) {
        await fileToCleanUp.delete();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengambil riwayat izin menggunakan sistem Caching (Offline First)
  Future<void> fetchRiwayatIzin({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      String? cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        _listRiwayat = jsonDecode(cachedData);
        notifyListeners();
      }
    }

    try {
      final response = await ApiClient().dio.get('/izin/riwayat');
      if (response.statusCode == 200 && response.data != null) {
        _listRiwayat = response.data['data'] ?? [];
        await prefs.setString(_cacheKey, jsonEncode(_listRiwayat));
      } else if (forceRefresh) {
        _listRiwayat = [];
      }
    } catch (e) {
      debugPrint('Gagal ambil riwayat izin: $e');
      if (forceRefresh) _listRiwayat = [];
    } finally {
      notifyListeners();
    }
  }
}
