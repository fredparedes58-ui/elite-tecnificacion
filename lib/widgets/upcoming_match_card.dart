
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpcomingMatchCard extends StatelessWidget {
  const UpcomingMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [colorScheme.primary.withAlpha(26), Colors.black.withAlpha(102)]
                : [colorScheme.primary.withAlpha(204), colorScheme.primary],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/noise_texture.png'), // Textura de ruido
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Column(
          children: [
            // Nombres de los equipos y logos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamDisplay('assets/images/real_madrid_logo.png', 'Real Madrid'),
                Text(
                  'VS',
                  style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildTeamDisplay('assets/images/barcelona_logo.png', 'Barcelona'),
              ],
            ),
            const SizedBox(height: 24),

            // Divisor estilizado
            Divider(
              color: Colors.white.withAlpha(51),
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(height: 16),

            // Información del partido (Fecha y Hora)
            _buildMatchInfo('SÁBADO, 26 DE OCTUBRE', '16:00 - Santiago Bernabéu', context),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar el logo y nombre de un equipo
  Widget _buildTeamDisplay(String logoPath, String teamName) {
    return Column(
      children: [
        Image.asset(logoPath, height: 80, width: 80),
        const SizedBox(height: 12),
        Text(
          teamName.toUpperCase(),
          style: GoogleFonts.robotoCondensed(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar la información del partido
  Widget _buildMatchInfo(String date, String timeAndLocation, BuildContext context) {
    return Column(
      children: [
        Text(
          date,
          style: GoogleFonts.robotoCondensed(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withAlpha(204),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          timeAndLocation,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.white.withAlpha(179),
          ),
        ),
      ],
    );
  }
}
