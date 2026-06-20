import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionHelper {
  static Future<void> requestAllPermissions() async {
    await Permission.notification.request();

    PermissionStatus statusLokasi = await Permission.location.status;
    if (!statusLokasi.isGranted) {
      statusLokasi = await Permission.location.request();
    }

    if (statusLokasi.isGranted) {
      PermissionStatus statusBackground =
          await Permission.locationAlways.status;
      if (!statusBackground.isGranted) {
        await Permission.locationAlways.request();
      }
    }

    await Permission.camera.request();

    Permission storagePermission = Permission.storage;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        storagePermission = Permission.photos;
      }
    }
    await storagePermission.request();
  }
}
