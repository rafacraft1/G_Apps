import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'secure_storage_helper.dart';

class DialogHelper {
  // [TAMBAHAN BARU] Global key untuk memanggil SnackBar tanpa BuildContext
  static final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showUpdateDialog(
      BuildContext context, String message, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.system_update, color: Colors.blue),
                SizedBox(width: 10),
                Text("Update Aplikasi",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(message),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await SecureStorageHelper.clearAll();
                    if (downloadUrl.isNotEmpty) {
                      final Uri url = Uri.parse(downloadUrl);
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      } catch (_) {}
                    }
                  },
                  child: const Text("Download Versi Terbaru",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // [TAMBAHAN BARU] SnackBar Dinamis via GlobalKey (Info, Error, Success)
  static void showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    final color = isError
        ? Colors.red.shade600
        : (isSuccess ? Colors.green.shade600 : Colors.blueGrey.shade800);
    final icon = isError
        ? Icons.error_outline
        : (isSuccess ? Icons.check_circle_outline : Icons.info_outline);

    scaffoldKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(message,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
  }

  // [TAMBAHAN BARU] Dialog untuk Error Fatal yang butuh konfirmasi tutup
  static void showErrorDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
