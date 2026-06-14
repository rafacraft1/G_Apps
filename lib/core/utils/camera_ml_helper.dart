import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraMlHelper {
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isAndroid) {
      var rotations = {
        0: InputImageRotation.rotation0deg,
        90: InputImageRotation.rotation90deg,
        180: InputImageRotation.rotation180deg,
        270: InputImageRotation.rotation270deg,
      };
      rotation = rotations[sensorOrientation];
    } else if (Platform.isIOS) {
      rotation = InputImageRotation.rotation90deg;
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    if (Platform.isAndroid) {
      // PERBAIKAN FINAL: ALGORITMA KONVERSI YUV_420_888 KE NV21
      // Memastikan urutan byte Y, U, dan V tidak saling tindih (interleaved)

      final WriteBuffer allBytes = WriteBuffer();

      // Lapisan Y (Luminance/Kecerahan) adalah pesawat utama
      final Plane yPlane = image.planes[0];
      allBytes.putUint8List(yPlane.bytes);

      // Lapisan U dan V (Chrominance/Warna)
      // Pada YUV420_888, panjang byte U dan V mungkin terpisah (Pixel Stride > 1)
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];

      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      // Konversi presisi agar sesuai dengan NV21:
      // NV21 mengharapkan susunan byte: YYYY... VUVUVU...
      if (uvPixelStride == 2) {
        // Jika format sudah interleaved (sebagian besar HP Android modern)
        allBytes.putUint8List(vPlane.bytes);
      } else {
        // Jika format terpisah (Planar murni), kita harus menggabungkannya manual
        int halfWidth = image.width ~/ 2;
        int halfHeight = image.height ~/ 2;

        for (int row = 0; row < halfHeight; row++) {
          for (int col = 0; col < halfWidth; col++) {
            // Masukkan nilai V lalu U (Karena NV21 = Y + VU)
            int vIndex = row * vPlane.bytesPerRow + col * uvPixelStride;
            int uIndex = row * uPlane.bytesPerRow + col * uvPixelStride;

            // Agar tidak out-of-bounds
            if (vIndex < vPlane.bytes.length && uIndex < uPlane.bytes.length) {
              allBytes.putUint8(vPlane.bytes[vIndex]);
              allBytes.putUint8(uPlane.bytes[uIndex]);
            }
          }
        }
      }

      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21, // WAJIB DIPAKSA KE NV21
          bytesPerRow: yPlane.bytesPerRow,
        ),
      );
    } else {
      // UNTUK iOS (Bawaannya sudah BGRA8888, aman untuk digabung langsung)
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
  }
}
