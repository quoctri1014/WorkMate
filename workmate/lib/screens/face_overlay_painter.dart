import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  final double circleRadius;
  final Color overlayColor;

  FaceOverlayPainter({required this.circleRadius, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: circleRadius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter old) => 
      old.circleRadius != circleRadius || old.overlayColor != overlayColor;
}
