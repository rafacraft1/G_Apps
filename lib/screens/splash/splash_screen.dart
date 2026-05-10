import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/utils/secure_storage_helper.dart';
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

  // Fungsi untuk memberi jeda animasi sekaligus mengecek status login
  Future<void> _jalankanSplashScreen() async {
    // 1. Beri waktu animasi Lottie untuk tampil (misal: 3 detik)
    await Future.delayed(const Duration(seconds: 3));

    // 2. Cek apakah siswa sudah memiliki token (sudah login sebelumnya)
    String? token = await SecureStorageHelper.getToken();

    if (!mounted) return;

    // 3. Arahkan ke layar yang tepat
    if (token != null && token.isNotEmpty) {
      // Jika token ada, langsung masuk ke Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Jika belum login, arahkan ke halaman Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.blue[600], // Warna latar belakang khas aplikasi Anda
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container untuk Animasi Lottie
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
                    // Fallback jika file lottie belum dimasukkan
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.school_rounded,
                          size: 100, color: Colors.blue);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Nama Aplikasi
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

            // Subtitle atau Slogan
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
      // Footer / Copyright di bagian bawah layar
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Versi 1.0.0',
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
