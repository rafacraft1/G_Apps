import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../core/utils/app_info_helper.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _jalankanSplashScreen();
  }

  Future<void> _jalankanSplashScreen() async {
    try {
      // Menggunakan Future.wait untuk menjalankan pembacaan token dan
      // jeda minimum (2 detik) secara paralel (bersamaan).
      final List<dynamic> results = await Future.wait([
        SecureStorageHelper.getToken(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      // Cegah memory leak: pastikan widget masih aktif sebelum melakukan navigasi
      if (!mounted) return;

      // Hasil pengambilan token berada di index 0 dari Future.wait
      final String? token = results[0] as String?;

      // OPTIMALISASI: Menggunakan pushAndRemoveUntil untuk memastikan
      // splash screen benar-benar terhapus dari tumpukan memori navigasi.
      if (token != null && token.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Jika terjadi error pada OS/Storage saat mengambil token,
      // aplikasi tidak akan freeze, melainkan aman di-routing ke LoginScreen.
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Lottie.asset(
                    'assets/animations/splash.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.school_rounded,
                          size: 100, color: Colors.blue);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Geofence App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem Presensi Pintar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            // [DIUBAH]: Menghilangkan versi aplikasi, hanya menampilkan copyright
            AppInfoHelper.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
