import 'package:flutter/material.dart';

/// Painter que dibuja una cuadrícula de ayuda cuando el snapping está activo
class SnapGridPainter extends CustomPainter {
  final bool showGrid;
  
  SnapGridPainter({this.showGrid = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Posiciones clave donde los jugadores "snapean"
    final snapPoints = [
      // DEFENSA
      const Offset(80, 480), const Offset(140, 500),
      const Offset(220, 500), const Offset(280, 480),
      const Offset(180, 520),
      
      // MEDIO CAMPO
      const Offset(80, 340), const Offset(140, 360),
      const Offset(180, 360), const Offset(220, 360),
      const Offset(280, 340),
      
      // ATAQUE
      const Offset(80, 180), const Offset(140, 200),
      const Offset(180, 180), const Offset(220, 200),
      const Offset(280, 180),
      
      // PORTERO
      const Offset(180, 600),
    ];

    // Dibujar círculos en cada snap point
    for (final point in snapPoints) {
      // Círculo exterior (indicador sutil)
      canvas.drawCircle(
        point,
        15,
        paint..color = Colors.white.withValues(alpha: 0.15),
      );
      
      // Círculo interior (punto central)
      canvas.drawCircle(
        point,
        4,
        paint..color = Colors.greenAccent.withValues(alpha: 0.4),
      );
      
      // Anillo de "magnetismo"
      paint
        ..color = Colors.greenAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(point, 20, paint);
      paint.style = PaintingStyle.fill;
    }

    // Líneas de ayuda horizontales (cada tercio del campo)
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Línea superior (tercio de ataque)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint2,
    );

    // Línea inferior (tercio de defensa)
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint2,
    );

    // Líneas verticales (bandas)
    final bandWidth = size.width / 3;
    
    // Banda izquierda
    canvas.drawLine(
      Offset(bandWidth, 0),
      Offset(bandWidth, size.height),
      paint2,
    );
    
    // Banda derecha
    canvas.drawLine(
      Offset(bandWidth * 2, 0),
      Offset(bandWidth * 2, size.height),
      paint2,
    );
  }

  @override
  bool shouldRepaint(SnapGridPainter oldDelegate) {
    return showGrid != oldDelegate.showGrid;
  }
}
