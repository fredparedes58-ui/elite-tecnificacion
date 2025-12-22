
import 'package:flutter/material.dart';

class DrawingPainter extends CustomPainter {
  final List<List<Offset?>> lines;
  final List<Offset?> currentLine;

  DrawingPainter({required this.lines, required this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        if (line[i] != null && line[i + 1] != null) {
          canvas.drawLine(line[i]!, line[i + 1]!, paint);
        }
      }
    }

    if (currentLine.length > 1) {
      for (int i = 0; i < currentLine.length - 1; i++) {
        if (currentLine[i] != null && currentLine[i + 1] != null) {
          canvas.drawLine(currentLine[i]!, currentLine[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
