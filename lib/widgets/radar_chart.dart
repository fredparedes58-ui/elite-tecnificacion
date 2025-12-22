import 'dart:math';
import 'package:flutter/material.dart';

class RadarChart extends StatelessWidget {
  final List<double> stats;
  final List<String> labels;

  const RadarChart({super.key, required this.stats, required this.labels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _RadarChartPainter(stats, labels, Theme.of(context).colorScheme),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> stats;
  final List<String> labels;
  final ColorScheme colors;

  _RadarChartPainter(this.stats, this.labels, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const angle = 2 * pi / 6;

    final paint = Paint()
      ..color = colors.onSurface.withAlpha(51)
      ..style = PaintingStyle.stroke;

    // Draw the web
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
    }

    for (var i = 0; i < 6; i++) {
      final x = center.dx + radius * cos(angle * i - pi / 2);
      final y = center.dy + radius * sin(angle * i - pi / 2);
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Draw the stats
    final statsPath = Path();
    for (var i = 0; i < 6; i++) {
      final statRadius = radius * stats[i];
      final x = center.dx + statRadius * cos(angle * i - pi / 2);
      final y = center.dy + statRadius * sin(angle * i - pi / 2);
      if (i == 0) {
        statsPath.moveTo(x, y);
      } else {
        statsPath.lineTo(x, y);
      }
    }
    statsPath.close();

    final statsPaint = Paint()
      ..color = colors.primary.withAlpha(128)
      ..style = PaintingStyle.fill;
    canvas.drawPath(statsPath, statsPaint);

    final statsStrokePaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(statsPath, statsStrokePaint);

    // Draw labels
    for (var i = 0; i < 6; i++) {
      final x = center.dx + (radius + 20) * cos(angle * i - pi / 2);
      final y = center.dy + (radius + 20) * sin(angle * i - pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: TextStyle(color: colors.onSurface, fontSize: 12)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.stats != stats || oldDelegate.labels != labels || oldDelegate.colors != colors;
  }
}
