import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraMlHelper {
  /// Mengonversi CameraImage (raw bytes) ke InputImage (format ML Kit)
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

    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) {
      return null;
    }
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
