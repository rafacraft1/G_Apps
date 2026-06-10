import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api/api_client.dart';

class TrackingService {
  static const String _queueKey = 'location_queue';

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

      if (queue.length > 3) {
        queue = queue.sublist(queue.length - 3);
      }

      await prefs.setStringList(
          _queueKey, queue.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      debugPrint('Error saveLocationPeriodic: $e');
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
    } catch (e) {
      debugPrint('Error sendLocationOnDemand: $e');
    }
  }
}
