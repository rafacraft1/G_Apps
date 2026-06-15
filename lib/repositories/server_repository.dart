import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class ServerRepository {
  static Future<Map<String, dynamic>?> getServerData() async {
    try {
      final response = await ApiClient().dio.get('/waktu_server');

      if (response.data != null &&
          (response.data['status'] == 200 ||
              response.data['status'] == 'success')) {
        var payload = response.data['data'] ?? response.data;

        return {
          'waktu': DateTime.parse(payload['waktu']),
          'is_libur': payload['is_libur'] == 1 || payload['is_libur'] == true,
          'nama_libur': payload['nama_libur'] ?? '',
          'jam_masuk': payload['jam_masuk'],
          'jam_pulang': payload['jam_pulang'],
          'lat_sekolah':
              double.tryParse(payload['lat_sekolah'].toString()) ?? 0.0,
          'lon_sekolah':
              double.tryParse(payload['lon_sekolah'].toString()) ?? 0.0,
          'radius': double.tryParse(payload['radius'].toString()) ?? 50.0,
          'nama_zona': payload['nama_zona'] ?? 'Area Sekolah',
          // PERBAIKAN FATAL: Parsing data 'pengaturan' agar jam buka absen terbaca oleh HomeScreen
          'pengaturan': payload['pengaturan'] ?? {},
        };
      }
    } catch (e) {
      debugPrint('Gagal ambil data server: $e');
    }
    return null;
  }
}
