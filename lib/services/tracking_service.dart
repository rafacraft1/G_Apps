import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api/api_client.dart';

class TrackingService {
  /// Mendapatkan Device ID secara independen untuk Pelacakan
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

  /// Fungsi ini HANYA dipanggil saat menerima perintah FCM dari Admin (Bekerja di Latar Belakang)
  static Future<void> sendLocationOnDemand() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      // Paksa ambil posisi akurasi tinggi saat itu juga
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

      // Langsung kirim data ke backend tanpa antrean
      await ApiClient().dio.post(
        'tracking/store',
        data: {
          'device_id': deviceId,
          'locations': [currentLoc]
        },
      );
    } catch (e) {
      debugPrint('Gagal sinkronisasi pelacakan on-demand: $e');
    }
  }
}
