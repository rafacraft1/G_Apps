import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

// Import Provider
import 'providers/auth_provider.dart';
import 'providers/pengumuman_provider.dart';
import 'providers/absensi_provider.dart';
import 'providers/izin_provider.dart';

// Import Helper & Screen
import 'screens/splash/splash_screen.dart';

// Import Tracking Service Baru
import 'services/tracking_service.dart';

// =====================================================================
// 1. MESIN BACKGROUND 15 MENIT (WORKMANAGER)
// =====================================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'periodic_tracking') {
      // Karena ini berjalan di Isolate terpisah, harus inisialisasi ulang
      WidgetsFlutterBinding.ensureInitialized();
      // Panggil fungsi simpan memori lokal (FIFO 3 Data)
      await TrackingService.saveLocationPeriodic();
    }
    return Future.value(true);
  });
}

// =====================================================================
// 2. FUNGSI INTI PELACAKAN (DIPAKAI OLEH FOREGROUND & BACKGROUND FCM)
// =====================================================================
Future<void> _prosesSinyalTracking(RemoteMessage message, String tipe) async {
  debugPrint("Sinyal Ping $tipe Diterima: ${message.data}");

  // Cocokkan payload dengan Controller CI4 ('action' => 'force_location_capture')
  if (message.data['action'] == 'force_location_capture') {
    // Tembakkan 4 data lokasi (3 lokal + 1 saat ini) ke web CI4
    await TrackingService.sendLocationOnDemand();
  }
}

// =====================================================================
// 3. BACKGROUND HANDLER UNTUK FCM (SAAT APLIKASI DITUTUP/BACKGROUND)
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

  // ---------------------------------------------------------
  // INISIALISASI WORKMANAGER (TRACKING 15 MENIT)
  // ---------------------------------------------------------
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set true jika ingin melihat log debug Workmanager
  );

  Workmanager().registerPeriodicTask(
    "tracking_15m_task",
    "periodic_tracking",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      // Tidak butuh internet untuk simpan memori lokal, hanya perlu device aktif
      networkType: NetworkType.not_required,
      requiresDeviceIdle: false,
    ),
  );

  // ---------------------------------------------------------
  // INISIALISASI FCM (TRIGGER DARI WEB ADMIN)
  // ---------------------------------------------------------
  // Daftarkan PINTU BELAKANG
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Daftarkan PINTU DEPAN
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
