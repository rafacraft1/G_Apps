import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Provider
import 'providers/auth_provider.dart';
import 'providers/pengumuman_provider.dart';
import 'providers/absensi_provider.dart';
import 'providers/izin_provider.dart';

// Import Helper & Screen
import 'core/utils/secure_storage_helper.dart';
import 'screens/splash/splash_screen.dart';

// =====================================================================
// FUNGSI INTI PELACAKAN (DIPAKAI OLEH FOREGROUND & BACKGROUND)
// =====================================================================
Future<void> _prosesSinyalTracking(RemoteMessage message, String tipe) async {
  debugPrint("Sinyal Ping $tipe Diterima: ${message.data}");

  // PERBAIKAN 1: Sesuaikan dengan payload yang dikirim dari Admin CI4
  if (message.data['action'] == 'fetch_location') {
    try {
      String? token = await SecureStorageHelper.getToken();
      if (token == null) return;

      Position posisi = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String baseUrl =
          dotenv.env['BASE_URL'] ?? 'http://192.168.0.105:8080/api/v1';

      Dio dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
      ));

      FormData formData = FormData.fromMap({
        'lat': posisi.latitude,
        'long': posisi.longitude,
      });

      // PERBAIKAN 2: Sesuaikan rute dengan TrackingApi.php di backend
      await dio.post(
        '/tracking/updateLokasi',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint("BERHASIL: Lokasi dikirim dari $tipe ke Server!");
    } catch (e) {
      debugPrint("GAGAL: Mengirim lokasi $tipe. Error: $e");
    }
  }
}

// =====================================================================
// BACKGROUND HANDLER (WAJIB TOP-LEVEL FUNCTION)
// =====================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await _prosesSinyalTracking(message, "Latar Belakang (Background)");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // 1. Daftarkan PINTU BELAKANG
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Daftarkan PINTU DEPAN
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
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
        ChangeNotifierProvider(create: (_) => IzinProvider()),
      ],
      child: MaterialApp(
        title: 'Sistem Absensi Geofence',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'GoogleSans',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
