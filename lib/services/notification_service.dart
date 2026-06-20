import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/utils/secure_storage_helper.dart';
import '../core/utils/dialog_helper.dart'; // [TAMBAHAN BARU]
import 'tracking_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await NotificationService.prosesSinyalFCM(
      message, "Latar Belakang (Background)");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Pengumuman Penting',
    description: 'Saluran ini digunakan untuk popup notifikasi pengumuman.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await prosesSinyalFCM(message, "Layar Aktif (Foreground)");
    });
  }

  static Future<void> prosesSinyalFCM(
      RemoteMessage message, String tipe) async {
    if (message.data['type'] == 'trigger_tracking' ||
        message.data['action'] == 'force_location_capture' ||
        message.data['action'] == 'fetch_location') {
      await TrackingService.sendLocationOnDemand();
      return;
    }

    if (message.notification != null) {
      RemoteNotification notification = message.notification!;
      AndroidNotification? android = message.notification?.android;

      if (android != null) {
        if (tipe == "Layar Aktif (Foreground)") {
          // [UPDATE UX] Tampilkan SnackBar mengambang di dalam aplikasi
          DialogHelper.showSnackBar(
            "${notification.title}\n${notification.body}",
            isSuccess: false,
            isError: false,
          );
        } else {
          // [UPDATE UX] Tetap gunakan notifikasi sistem jika di background
          _plugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
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
  }

  static Future<void> updateFCMToken() async {
    try {
      String? token = await SecureStorageHelper.getToken();
      if (token == null || token.isEmpty) return;

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        FormData formData = FormData.fromMap({'fcm_token': fcmToken});
        await ApiClient().dio.post(ApiEndpoints.updateFcm, data: formData);
      }
    } catch (_) {}
  }
}
