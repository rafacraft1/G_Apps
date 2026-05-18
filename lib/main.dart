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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'periodic_tracking') {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await TrackingService.saveLocationPeriodic();
    }
    return Future.value(true);
  });
}

Future<void> _prosesSinyalTracking(RemoteMessage message, String tipe) async {
  debugPrint("Sinyal Ping $tipe Diterima: ${message.data}");
  if (message.data['action'] == 'force_location_capture') {
    await TrackingService.sendLocationOnDemand();
  }
}

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

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Workmanager().registerPeriodicTask(
    "tracking_15m_task",
    "periodic_tracking",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresDeviceIdle: false,
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
        home:
            const SplashScreen(), // Lottie Anda akan mengambil alih secara instan
      ),
    );
  }
}
