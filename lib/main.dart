import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. IMPORT DOTENV

// Import Provider
import 'providers/auth_provider.dart';
import 'providers/pengumuman_provider.dart';
import 'providers/absensi_provider.dart';

// Import Helper & Screen
import 'core/utils/secure_storage_helper.dart';
import 'screens/splash/splash_screen.dart';

// =====================================================================
// FUNGSI INTI PELACAKAN (DIPAKAI OLEH FOREGROUND & BACKGROUND)
// =====================================================================
Future<void> _prosesSinyalTracking(RemoteMessage message, String tipe) async {
  debugPrint("Sinyal Ping $tipe Diterima: ${message.data}");

  // Jika Web CI4 mengirim aksi 'TRACKING_REQUEST'[cite: 7]
  if (message.data['action'] == 'TRACKING_REQUEST') {
    try {
      // 1. Cek Token Siswa (Agar tahu siapa yg dilacak)[cite: 7]
      String? token = await SecureStorageHelper.getToken();
      if (token == null) return;

      // 2. Tembak Lokasi Asli[cite: 7]
      Position posisi = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // --- PERBAIKAN: Ambil URL dari .env ---
      // Gunakan nilai default lokal jika gagal membaca .env untuk mencegah crash
      String baseUrl =
          dotenv.env['BASE_URL'] ?? 'http://192.168.0.105:8080/api/v1';

      // 3. Kirim ke Backend CI4[cite: 7]
      Dio dio = Dio(BaseOptions(
        baseUrl: baseUrl, // <-- 2. GUNAKAN VARIABEL DARI .ENV
        connectTimeout: const Duration(seconds: 15),
      ));

      FormData formData = FormData.fromMap({
        'lat': posisi.latitude,
        'long': posisi.longitude,
      });

      await dio.post(
        '/tracking/update',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint("BERHASIL: Lokasi dikirim dari $tipe ke Server/Firebase!");
    } catch (e) {
      debugPrint("GAGAL: Mengirim lokasi $tipe. Error: $e");
    }
  }
}

// =====================================================================
// ⚠️ BACKGROUND HANDLER (WAJIB DI LUAR CLASS, HARUS TOP-LEVEL FUNCTION)
// =====================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase aktif walau UI tidak jalan[cite: 7]
  await Firebase.initializeApp();

  // --- 3. LOAD DOTENV DI BACKGROUND ---
  // Sangat penting karena saat aplikasi mati, fungsi main() tidak dijalankan
  await dotenv.load(fileName: ".env");

  // Lemparkan ke fungsi inti[cite: 7]
  await _prosesSinyalTracking(message, "Latar Belakang (Background)");
}

void main() async {
  // Pastikan core Flutter sudah jalan sebelum panggil Firebase[cite: 7]
  WidgetsFlutterBinding.ensureInitialized();

  // --- 4. LOAD DOTENV DI FOREGROUND ---
  await dotenv.load(fileName: ".env");

  // Inisialisasi Firebase[cite: 7]
  await Firebase.initializeApp();

  // 1. Daftarkan PINTU BELAKANG (Aplikasi Ditutup / Background)[cite: 7]
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Daftarkan PINTU DEPAN (Aplikasi Sedang Dibuka / Foreground)[cite: 7]
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Lemparkan ke fungsi inti[cite: 7]
    await _prosesSinyalTracking(message, "Layar Aktif (Foreground)");
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PengumumanProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiProvider()),
      ],
      child: MaterialApp(
        title: 'Sistem Absensi Geofence',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
