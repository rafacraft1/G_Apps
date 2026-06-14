import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/api/api_client.dart';

class TrackingService {
  /// Mendapatkan Device ID secara independen untuk Background Service
  static Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.brand}_${androidInfo.model}_Android-${androidInfo.version.release}_${androidInfo.id}"
            .replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return "Apple_${iosInfo.model}_iOS-${iosInfo.systemVersion}_${iosInfo.identifierForVendor ?? 'unknown_id'}"
            .replaceAll(' ', '_');
      }
    } catch (e) {
      debugPrint('Tracking Device ID Error: $e');
    }
    return 'unknown_device';
  }

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'tracking_channel',
        initialNotificationTitle: 'Geofence System Standby',
        initialNotificationContent:
            'Aplikasi siap menerima instruksi sinkronisasi.',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startTracking() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await dotenv.load(fileName: ".env");

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      // Listener opsional jika dipicu dari interaksi UI di Foreground
      service.on('triggerLocation').listen((event) async {
        await sendLocationOnDemand();
      });
    }

    // PENGIRIMAN OTOMATIS BERKALA DIHAPUS.
    // Service hanya diam (standby) menjaga akses lokasi OS agar tidak diputus.
  }

  /// Fungsi ini HANYA dipanggil saat menerima perintah FCM dari Admin
  static Future<void> sendLocationOnDemand() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      Map<String, dynamic> currentLoc = {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'is_mock': pos.isMocked ? 1 : 0,
        'waktu': DateTime.now().toLocal().toString().split('.')[0],
        'tipe': 'trigger'
      };

      String deviceId = await _getDeviceId();

      // Langsung kirim 1 data aktual tanpa sistem antrean (queue)
      await ApiClient().dio.post(
        'tracking/store',
        data: {
          'device_id': deviceId,
          'locations': [currentLoc]
        },
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
