import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class TrackingService {
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
    } catch (_) {}
    return 'unknown_device';
  }

  static Future<void> sendLocationOnDemand() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String deviceId = await _getDeviceId();

      await ApiClient().dio.post(
            ApiEndpoints.updateLokasi,
            data: {
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'accuracy': pos.accuracy,
              'is_mock': pos.isMocked ? 1 : 0,
              'device_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            },
            options: Options(headers: {'X-Device-ID': deviceId}),
          );
    } catch (_) {}
  }
}
