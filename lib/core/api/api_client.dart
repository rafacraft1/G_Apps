import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/secure_storage_helper.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;

  // Pastikan URL mengarah ke folder /api
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? 'http://192.168.0.105:8080/api/v1';

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await SecureStorageHelper.getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('API Error: ${e.response?.statusCode} - ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  static Future<Map<String, dynamic>?> getServerData() async {
    try {
      // Pastikan endpoint sesuai dengan rute di CI4
      final response = await ApiClient().dio.get('/waktu_server');

      if (response.data != null &&
          (response.data['status'] == 200 ||
              response.data['status'] == 'success')) {
        // PERBAIKAN: Ambil payload dari dalam object 'data'
        var payload = response.data['data'];

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
        };
      }
    } catch (e) {
      debugPrint('Gagal ambil data server: $e');
    }
    return null;
  }
}
