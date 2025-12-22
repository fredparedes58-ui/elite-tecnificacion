
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';

class PlayerStatCard extends StatelessWidget {
  final Player player;

  const PlayerStatCard({super.key, required this.player});

  // Generador de valoración simulada para fines de diseño
  int get _simulatedOverall {
    return 80 + (player.name.hashCode % 15);
  }

  // Determina el color basado en la valoración
  Color _getRatingColor(int rating) {
    if (rating >= 90) return Colors.green.shade400;
    if (rating >= 85) return Colors.lightGreen.shade400;
    if (rating >= 80) return Colors.yellow.shade600;
    return Colors.orange.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final rating = _simulatedOverall;
    final ratingColor = _getRatingColor(rating);
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shadowColor: isDarkMode ? Colors.black.withAlpha(128) : Colors.grey.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage(player.image),
          backgroundColor: Theme.of(context).colorScheme.surface, // Fondo mientras carga
        ),
        title: Text(
          player.name,
          style: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          player.role ?? 'Sin Posición', // Muestra el rol o un texto por defecto
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: textTheme.bodySmall?.color?.withAlpha(179),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'OVR', // Overall Rating
              style: GoogleFonts.robotoCondensed(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textTheme.bodySmall?.color?.withAlpha(128),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rating.toString(),
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ratingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
