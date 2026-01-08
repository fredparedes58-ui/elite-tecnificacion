
import 'package:flutter/material.dart';

// El widget principal que contiene el campo de juego con imagen real
class PitchView extends StatelessWidget {
  const PitchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo del campo de fútbol real
            Image.network(
              'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=1200&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback a imagen alternativa si falla la primera
                return Image.network(
                  'https://images.pexels.com/photos/399187/pexels-photo-399187.jpeg?auto=compress&cs=tinysrgb&w=1200',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error2, stackTrace2) {
                    // Último fallback: degradado verde oscuro
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1B5E20),
                            const Color(0xFF0D3D15),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFF1B5E20),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),
            // Overlay oscuro sutil para mejorar contraste con jugadores
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(25),
                    Colors.black.withAlpha(51),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter eliminado - Ahora se usa imagen real de campo de fútbol
