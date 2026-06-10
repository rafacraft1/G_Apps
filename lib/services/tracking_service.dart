import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/api/api_client.dart';

class TrackingService {
  static const String _queueKey = 'location_queue';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'tracking_channel',
        initialNotificationTitle: 'Geofence Tracking Aktif',
        initialNotificationContent: 'Memantau lokasi perangkat',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
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
    }

    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await saveLocationPeriodic();
        }
      } else {
        await saveLocationPeriodic();
      }
    });
  }

  static Future<void> saveLocationPeriodic() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      List<String> queueStr = prefs.getStringList(_queueKey) ?? [];
      List<Map<String, dynamic>> queue =
          queueStr.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      queue.add({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'waktu': DateTime.now().toLocal().toString().split('.')[0],
        'tipe': 'berkala'
      });

      if (queue.length > 10) {
        queue = queue.sublist(queue.length - 10);
      }

      await prefs.setStringList(
          _queueKey, queue.map((e) => jsonEncode(e)).toList());

      await _syncLocationToServer(queue, prefs);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> _syncLocationToServer(
      List<Map<String, dynamic>> queue, SharedPreferences prefs) async {
    try {
      if (queue.isEmpty) return;

      final response = await ApiClient().dio.post(
        '/tracking/store',
        data: {'locations': queue},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setStringList(_queueKey, []);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> sendLocationOnDemand() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      Map<String, dynamic> currentLoc = {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'waktu': DateTime.now().toLocal().toString().split('.')[0],
        'tipe': 'trigger'
      };

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> queueStr = prefs.getStringList(_queueKey) ?? [];
      List<Map<String, dynamic>> queue =
          queueStr.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      List<Map<String, dynamic>> finalLocations = [...queue, currentLoc];

      await ApiClient().dio.post(
        '/tracking/store',
        data: {'locations': finalLocations},
      );

      await prefs.setStringList(_queueKey, []);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
