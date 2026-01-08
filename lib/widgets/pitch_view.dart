import 'package:flutter/material.dart';

// Widget principal que contiene el campo de juego con imagen real vista aérea
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
            // Imagen de fondo del campo de fútbol - VISTA SUPERIOR (aérea) con patrón de rayas
            Image.network(
              'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200&q=80&fit=crop', // Campo vista aérea con patrón de rayas
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback 1: Campo con patrón de rayas de césped muy visible
                return Image.network(
                  'https://images.pexels.com/photos/274422/pexels-photo-274422.jpeg?auto=compress&cs=tinysrgb&w=1200&h=800&fit=crop', // Campo con líneas claras y rayas de césped
                  fit: BoxFit.cover,
                  errorBuilder: (context, error2, stackTrace2) {
                    // Fallback 2: Otra vista aérea con marcas visibles
                    return Image.network(
                      'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?w=1200&q=80&fit=crop', // Cancha desde arriba con marcas visibles
                      fit: BoxFit.cover,
                      errorBuilder: (context, error3, stackTrace3) {
                        // Fallback 3: Campo con patrón de rayas alternadas
                        return Image.network(
                          'https://images.unsplash.com/photo-1575361204480-81d3e465d0b4?w=1200&q=80&fit=crop', // Campo verde con rayas
                          fit: BoxFit.cover,
                          errorBuilder: (context, error4, stackTrace4) {
                            // Último fallback: Campo dibujado con gradiente verde y patrón de rayas
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF2D5016),
                                    const Color(0xFF3A6B1F),
                                    const Color(0xFF4A7C2A),
                                    const Color(0xFF3A6B1F),
                                    const Color(0xFF2D5016),
                                  ],
                                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF2D5016),
                        const Color(0xFF3A6B1F),
                      ],
                    ),
                  ),
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
            // Overlay oscuro MUY SUTIL para mejorar contraste sin opacar demasiado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(8), // Muy sutil arriba
                    Colors.black.withAlpha(20), // Ligeramente más oscuro abajo
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
