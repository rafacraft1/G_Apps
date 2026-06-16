import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageHelper {
  static Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final extensionIndex = filePath.lastIndexOf('.');
    final outPath = "${filePath.substring(0, extensionIndex)}_compressed.jpg";

    XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 60,
      minWidth: 800,
      minHeight: 800,
    );

    if (compressedFile != null) {
      return File(compressedFile.path);
    }
    return null;
  }
}
