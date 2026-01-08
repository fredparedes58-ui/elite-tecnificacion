
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
            // Imagen de fondo del campo de fútbol - VISTA SUPERIOR (aérea)
            Image.network(
              'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200&q=80', // Campo de fútbol vista aérea
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback 1: Vista superior alternativa
                return Image.network(
                  'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?w=1200&q=80', // Cancha desde arriba
                  fit: BoxFit.cover,
                  errorBuilder: (context, error2, stackTrace2) {
                    // Fallback 2: Otra vista aérea
                    return Image.network(
                      'https://images.pexels.com/photos/274422/pexels-photo-274422.jpeg?auto=compress&cs=tinysrgb&w=1200', // Campo con líneas claras
                      fit: BoxFit.cover,
                      errorBuilder: (context, error3, stackTrace3) {
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
            // Overlay oscuro MUY SUTIL para no opacar la vista aérea
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(15), // Más claro que antes
                    Colors.black.withAlpha(30), // Más claro que antes
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
