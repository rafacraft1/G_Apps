import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Import Provider
import 'providers/auth_provider.dart';
import 'providers/pengumuman_provider.dart';
import 'providers/absensi_provider.dart';
import 'providers/izin_provider.dart';

// Import Helper & Screen
import 'screens/splash/splash_screen.dart';
import 'services/tracking_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Pengumuman Penting',
  description: 'Saluran ini digunakan untuk popup notifikasi pengumuman.',
  importance: Importance.max,
);

// ✅ FUNGSI PEMAKSA IZIN KOMPREHENSIF
Future<void> _pastikanSemuaIzin() async {
  // 1. Minta Izin Notifikasi (Wajib untuk Android 13+)
  await Permission.notification.request();

  // 2. Minta Izin Lokasi Utama (Saat Aplikasi Digunakan)
  PermissionStatus statusLokasi = await Permission.location.status;
  if (!statusLokasi.isGranted) {
    statusLokasi = await Permission.location.request();
  }

  // 3. Minta Izin Lokasi Latar Belakang (Selalu Diizinkan / Always Allow)
  // Aturan Android: Hanya bisa diminta JIKA izin lokasi utama sudah diberikan
  if (statusLokasi.isGranted) {
    PermissionStatus statusBackground = await Permission.locationAlways.status;
    if (!statusBackground.isGranted) {
      await Permission.locationAlways.request();
    }
  }
}

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

Future<void> _prosesSinyalFCM(RemoteMessage message, String tipe) async {
  debugPrint("Sinyal FCM $tipe Diterima!");

  if (message.data['action'] == 'force_location_capture' ||
      message.data['action'] == 'fetch_location') {
    await TrackingService.sendLocationOnDemand();
    return;
  }

  if (tipe == "Layar Aktif (Foreground)" && message.notification != null) {
    RemoteNotification notification = message.notification!;
    AndroidNotification? android = message.notification?.android;

    if (android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await _prosesSinyalFCM(message, "Latar Belakang (Background)");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // ✅ JALANKAN PENGECEKAN IZIN BERUNTUN SEBELUM APLIKASI MEMUAT UI
  await _pastikanSemuaIzin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

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
    await _prosesSinyalFCM(message, "Layar Aktif (Foreground)");
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
