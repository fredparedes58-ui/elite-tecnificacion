
import 'package:flutter/material.dart';

// El widget principal que contiene el campo de juego.
class PitchView extends StatelessWidget {
  const PitchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Usamos un gradiente para darle un aspecto más moderno al césped.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[700]!, // Un verde ligeramente más claro en la parte superior
            Colors.green[800]!, // Un verde más oscuro en la parte inferior
          ],
        ),
        boxShadow: [
          // Sombra interior para dar profundidad
          BoxShadow(
            color: Colors.black.withAlpha(77), // Corrección: withOpacity -> withAlpha
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
      ),
      // El CustomPaint se encarga de dibujar las líneas del campo.
      child: CustomPaint(
        painter: PitchPainter(),
        child: Container(), // El hijo es necesario para que el painter se dibuje
      ),
    );
  }
}

// El CustomPainter que dibuja las líneas del campo de fútbol.
class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(153) // Corrección: withOpacity -> withAlpha
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Grosor de las líneas

    final width = size.width;
    final height = size.height;

    // 1. Línea de medio campo
    canvas.drawLine(Offset(width / 2, 0), Offset(width / 2, height), paint);

    // 2. Círculo central
    canvas.drawCircle(Offset(width / 2, height / 2), width / 8, paint);
    // Punto central
    canvas.drawCircle(
        Offset(width / 2, height / 2),
        3,
        paint..style = PaintingStyle.fill // Rellenamos el punto central
        );
    paint.style = PaintingStyle.stroke; // Restauramos el estilo

    // 3. Bordes del campo
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // 4. Área de penalti izquierda
    final penaltyAreaWidth = width * 0.2; // Ancho del área
    final penaltyAreaHeight = height * 0.6; // Alto del área
    final penaltyAreaTop = (height - penaltyAreaHeight) / 2;
    final penaltyAreaRectLeft = Rect.fromLTWH(0, penaltyAreaTop, penaltyAreaWidth, penaltyAreaHeight);
    canvas.drawRect(penaltyAreaRectLeft, paint);

    // 5. Área de penalti derecha
    final penaltyAreaRectRight = Rect.fromLTWH(width - penaltyAreaWidth, penaltyAreaTop, penaltyAreaWidth, penaltyAreaHeight);
    canvas.drawRect(penaltyAreaRectRight, paint);

    // 6. Arco del área de penalti izquierda (Media luna)
    final arcRectLeft = Rect.fromCircle(center: Offset(penaltyAreaWidth, height / 2), radius: height * 0.15);
    canvas.drawArc(arcRectLeft, -1.1, 2.2, false, paint); // Usamos ángulos en radianes

    // 7. Arco del área de penalti derecha (Media luna)
    final arcRectRight = Rect.fromCircle(center: Offset(width - penaltyAreaWidth, height / 2), radius: height * 0.15);
    canvas.drawArc(arcRectRight, 2.04, 2.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No necesitamos repintar a menos que cambien las dimensiones
  }
}
