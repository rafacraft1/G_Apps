import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/secure_storage_helper.dart';

class TrackingService {
  static const String _queueKey = 'location_queue';

  // 1. DIJALANKAN OTOMATIS SETIAP 15 MENIT (OLEH WORKMANAGER)
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

      // Tambahkan lokasi baru ke memori
      queue.add({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'waktu': DateTime.now().toLocal().toString().split('.')[0],
        'tipe': 'berkala'
      });

      // KONSEP FIFO: Jika data lebih dari 3, buang yang paling lama (index 0)
      if (queue.length > 3) {
        queue = queue.sublist(queue.length - 3);
      }

      await prefs.setStringList(
          _queueKey, queue.map((e) => jsonEncode(e)).toList());
      debugPrint(
          "Background Tracking: Lokasi 15 menit berhasil disimpan ke memori lokal.");
    } catch (e) {
      debugPrint('Error saveLocationPeriodic: $e');
    }
  }

  // 2. DIJALANKAN SAAT WEB ADMIN MENEKAN "LACAK SEKARANG" (VIA FCM)
  static Future<void> sendLocationOnDemand() async {
    try {
      await dotenv.load(fileName: ".env");
      String baseUrl = dotenv.env['BASE_URL'] ?? '';
      if (baseUrl.isEmpty) return;

      String? siswaId = await SecureStorageHelper.getUserId();
      if (siswaId == null) return;

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

      // Tarik 3 data riwayat dari memori lokal
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> queueStr = prefs.getStringList(_queueKey) ?? [];
      List<Map<String, dynamic>> queue =
          queueStr.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      // Gabungkan 3 antrean lokal + 1 lokasi saat ini
      List<Map<String, dynamic>> finalLocations = [...queue, currentLoc];

      // Tembakkan ke Jembatan Cache CodeIgniter 4
      Dio dio = Dio();
      await dio.post('$baseUrl/tracking/store',
          data: {'siswa_id': siswaId, 'locations': finalLocations},
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }));

      debugPrint(
          "Tracking On-Demand: 4 Titik Lokasi berhasil dilempar ke Web Admin!");
    } catch (e) {
      debugPrint('Error sendLocationOnDemand: $e');
    }
  }
}
