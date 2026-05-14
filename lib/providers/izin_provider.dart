import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class IzinProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _listRiwayat = [];
  List<dynamic> get listRiwayat => _listRiwayat;

  // Fungsi untuk mengirim form pengajuan ke server
  Future<bool> ajukanIzin({
    required String tanggalMulai,
    required String tanggalSelesai,
    required String jenis,
    required String alasan,
    required File buktiFoto,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String fileName = buktiFoto.path.split('/').last;

      // Merakit data sesuai field allowedFields di PengajuanIzinModel CI4
      FormData formData = FormData.fromMap({
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'jenis': jenis,
        'alasan': alasan,
        'bukti_foto': await MultipartFile.fromFile(
          buktiFoto.path,
          filename: fileName,
        ),
      });

      final response = await ApiClient().dio.post(
            '/izin/ajukan',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchRiwayatIzin(); // Segarkan riwayat jika sukses
        return true;
      } else {
        throw response.data['message'] ?? 'Gagal mengajukan izin.';
      }
    } on DioException catch (e) {
      String pesanError = 'Gagal menghubungi server.';
      if (e.response?.data != null && e.response?.data is Map) {
        // CI4 validation errors biasanya ada di key ['messages']
        if (e.response?.data['messages'] != null) {
          final errors = e.response?.data['messages'];
          if (errors is Map) {
            pesanError = errors.values.first.toString();
          } else {
            pesanError = errors.toString();
          }
        } else {
          pesanError = e.response?.data['message'] ?? pesanError;
        }
      }
      throw pesanError;
    } catch (e) {
      throw 'Terjadi kesalahan sistem: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk mengambil history izin
  Future<void> fetchRiwayatIzin() async {
    try {
      final response = await ApiClient().dio.get('/izin/riwayat');
      if (response.statusCode == 200 && response.data != null) {
        _listRiwayat = response.data['data'] ?? [];
      } else {
        _listRiwayat = [];
      }
    } catch (e) {
      debugPrint('Gagal ambil riwayat izin: $e');
      _listRiwayat = [];
    } finally {
      notifyListeners();
    }
  }
}
