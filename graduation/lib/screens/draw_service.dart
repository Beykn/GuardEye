// draw_service.dart
import 'package:flutter/material.dart';

class BoxPainter extends CustomPainter {
  final List<dynamic> recognitions;
  final Size imageSize;
  final Size screenSize;
  static const double CONFIDENCE_THRESHOLD = 0.5;

  BoxPainter(this.recognitions, this.imageSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black54;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < recognitions[2][0]; i++) {
      if (recognitions[0][0][i] > CONFIDENCE_THRESHOLD) {
        var left = recognitions[1][0][i][1] * screenSize.width;
        var top = recognitions[1][0][i][0] * screenSize.height;
        var right = recognitions[1][0][i][3] * screenSize.width;
        var bottom = recognitions[1][0][i][2] * screenSize.height;

        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

        final label = 'Class ${recognitions[3][0][i].toInt()}: ${(recognitions[0][0][i] * 100).toStringAsFixed(0)}%';
        textPainter.text = TextSpan(text: label, style: textStyle);
        textPainter.layout();

        final textWidth = textPainter.width + 8;
        final textHeight = textPainter.height + 8;
        canvas.drawRect(Rect.fromLTWH(left, top - textHeight, textWidth, textHeight), backgroundPaint);
        textPainter.paint(canvas, Offset(left + 4, top - textHeight + 4));
      }
    }
  }

  @override
  bool shouldRepaint(BoxPainter oldDelegate) => true;
}