import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoHelper {
  static const String copyright = "© 2026 Nurindra. All Rights Reserved.";

  static Widget buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copyright,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontFamily: 'GoogleSans',
            ),
          ),
          const SizedBox(height: 2),
          // Menggunakan FutureBuilder agar otomatis mengambil versi pubspec.yaml
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              String versionText = "Memuat versi...";

              if (snapshot.hasData) {
                versionText =
                    "Versi ${snapshot.data!.version}+${snapshot.data!.buildNumber}";
              } else if (snapshot.hasError) {
                // Fallback jika package_info_plus gagal memuat
                versionText = "Versi 2.0.1";
              }

              return Text(
                versionText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                  fontFamily: 'GoogleSans',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
