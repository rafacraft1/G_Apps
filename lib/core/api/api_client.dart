import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/secure_storage_helper.dart';
import '../utils/dialog_helper.dart';
import 'api_endpoints.dart';
import '../../main.dart';
import '../../screens/auth/login_screen.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late Dio dio;
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshQueue = [];

  String? _cachedAppVersion;

  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  factory ApiClient() {
    return _instance;
  }

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

          try {
            if (_cachedAppVersion == null) {
              PackageInfo packageInfo = await PackageInfo.fromPlatform();
              _cachedAppVersion = packageInfo.version;
            }
            options.headers['X-App-Version'] = _cachedAppVersion;
          } catch (_) {
            options.headers['X-App-Version'] = '1.0.0';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 426) {
            String pesan = e.response?.data['message'] ??
                'Harap update aplikasi ke versi terbaru.';
            String urlDownload = e.response?.data['download_url'] ?? '';

            final context = navigatorKey.currentContext;
            if (context != null) {
              DialogHelper.showUpdateDialog(context, pesan, urlDownload);
            }
            return handler.next(e);
          }

          if (e.response?.statusCode == 401) {
            RequestOptions options = e.requestOptions;

            if (options.path.contains(ApiEndpoints.refresh) ||
                options.path.contains(ApiEndpoints.login)) {
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
                ApiEndpoints.refresh,
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
            } catch (_) {
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

  Future<void> _forceLogout() async {
    await SecureStorageHelper.clearAll();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
