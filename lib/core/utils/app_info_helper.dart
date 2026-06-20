import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoHelper {
  static String appVersion = "2.0.0";
  static const String copyright = "© 2026 Nurindra. All Rights Reserved.";

  static Future<void> initialize() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    } catch (_) {}
  }

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
          Text(
            "Versi $appVersion",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
              fontFamily: 'GoogleSans',
            ),
          ),
        ],
      ),
    );
  }
}
