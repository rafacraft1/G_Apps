import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/secure_storage_helper.dart';
import '../../main.dart';
import '../../screens/auth/login_screen.dart';

/// Singleton class untuk manajemen koneksi API HTTP menggunakan Dio
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late Dio dio;
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshQueue = [];

  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Factory constructor untuk mengembalikan instance singleton
  factory ApiClient() {
    return _instance;
  }

  /// Internal constructor untuk inisialisasi Dio dan Interceptor
  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            RequestOptions options = e.requestOptions;

            if (options.path.contains('auth/refresh') ||
                options.path.contains('auth/login')) {
              await _forceLogout();
              return handler.next(e);
            }

            if (_isRefreshing) {
              _refreshQueue.add((newToken) {
                options.headers['Authorization'] = 'Bearer $newToken';
                dio.fetch(options).then(
                      (response) => handler.resolve(response),
                      onError: (err) => handler.reject(err),
                    );
              });
              return;
            }

            _isRefreshing = true;
            String? refreshToken = await SecureStorageHelper.getRefreshToken();

            if (refreshToken == null) {
              await _forceLogout();
              return handler.next(e);
            }

            try {
              Dio refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

              Response response = await refreshDio.post(
                'auth/refresh',
                data: {'refresh_token': refreshToken},
                options:
                    Options(contentType: Headers.formUrlEncodedContentType),
              );

              if (response.statusCode == 200 &&
                  response.data['access_token'] != null) {
                String newAccessToken = response.data['access_token'];

                await SecureStorageHelper.saveTokens(
                    access: newAccessToken, refresh: refreshToken);

                options.headers['Authorization'] = 'Bearer $newAccessToken';

                _isRefreshing = false;
                for (var callback in _refreshQueue) {
                  callback(newAccessToken);
                }
                _refreshQueue.clear();

                Response retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (err) {
              _isRefreshing = false;
              _refreshQueue.clear();
              await _forceLogout();
              return handler.reject(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Memaksa pengguna keluar dari sesi jika token gagal diperbarui
  Future<void> _forceLogout() async {
    await SecureStorageHelper.clearAll();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
