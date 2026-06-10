import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/auth_provider.dart';
import 'providers/pengumuman_provider.dart';
import 'providers/absensi_provider.dart';
import 'providers/izin_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'services/tracking_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Pengumuman Penting',
  description: 'Saluran ini digunakan untuk popup notifikasi pengumuman.',
  importance: Importance.max,
);

Future<void> _pastikanSemuaIzin() async {
  await Permission.notification.request();

  PermissionStatus statusLokasi = await Permission.location.status;
  if (!statusLokasi.isGranted) {
    statusLokasi = await Permission.location.request();
  }

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
        navigatorKey: navigatorKey,
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
