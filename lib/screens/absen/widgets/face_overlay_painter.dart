import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);

    final width = size.width * 0.70;
    final height = size.height * 0.45;
    final center = Offset(size.width / 2, size.height * 0.40);
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(rect, borderPaint);

    final bracketPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    double cornerLength = 35.0;

    canvas.drawPath(
        Path()
          ..moveTo(rect.left, rect.top + cornerLength)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.left + cornerLength, rect.top),
        bracketPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rect.right - cornerLength, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.top + cornerLength),
        bracketPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rect.left, rect.bottom - cornerLength)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.left + cornerLength, rect.bottom),
        bracketPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rect.right - cornerLength, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.right, rect.bottom - cornerLength),
        bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
