import 'package:permission_handler/permission_handler.dart';

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
  }
}
