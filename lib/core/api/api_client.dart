import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/secure_storage_helper.dart';
import '../../main.dart';
import '../../screens/auth/login_screen.dart';

/// Singleton class untuk manajemen koneksi API HTTP menggunakan Dio
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late Dio dio;
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshQueue = [];

  // Cache versi aplikasi agar tidak memanggil platform channel berulang kali
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
          // 1. Sisipkan Token Otorisasi
          String? token = await SecureStorageHelper.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Sisipkan Versi Aplikasi
          try {
            if (_cachedAppVersion == null) {
              PackageInfo packageInfo = await PackageInfo.fromPlatform();
              _cachedAppVersion = packageInfo.version;
            }
            options.headers['X-App-Version'] = _cachedAppVersion;
          } catch (e) {
            debugPrint("Gagal membaca versi aplikasi: $e");
            options.headers['X-App-Version'] = '1.0.0'; // Fallback aman
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // ==========================================
          // TANGANI ERROR 426: UPGRADE REQUIRED
          // ==========================================
          if (e.response?.statusCode == 426) {
            String pesan = e.response?.data['message'] ??
                'Harap update aplikasi ke versi terbaru.';
            String urlDownload = e.response?.data['download_url'] ?? '';

            _showUpdateDialog(pesan, urlDownload);
            return handler.next(e); // Lanjutkan error agar request dibatalkan
          }

          // ==========================================
          // TANGANI ERROR 401: TOKEN EXPIRED
          // ==========================================
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

  Future<void> _forceLogout() async {
    await SecureStorageHelper.clearAll();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Dialog pemblokiran untuk update aplikasi
  void _showUpdateDialog(String message, String downloadUrl) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false, // Wajib diklik, tidak bisa di-tap di luar
        builder: (BuildContext context) {
          // Gunakan WillPopScope/PopScope untuk mencegah tombol 'Back' bawaan HP Android
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Update Aplikasi",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Text(message),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      // 1. Bersihkan semua sesi untuk memastikan "Clean Install Experience"
                      await SecureStorageHelper.clearAll();

                      // 2. Buka Link APK
                      if (downloadUrl.isNotEmpty) {
                        final Uri url = Uri.parse(downloadUrl);
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            debugPrint(
                                'Tidak dapat membuka link: $downloadUrl');
                          }
                        } catch (e) {
                          debugPrint('Error saat membuka browser: $e');
                        }
                      }
                    },
                    child: const Text("Download Versi Terbaru",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
