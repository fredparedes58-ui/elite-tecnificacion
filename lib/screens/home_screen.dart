
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/live_standings_card.dart';
import 'package:myapp/widgets/squad_status_card.dart';
import 'package:myapp/widgets/upcoming_match_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'COMMAND CENTER',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Bienvenido de nuevo, Entrenador.',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w300, // Un peso más ligero para un look moderno
                  color: textTheme.bodyLarge?.color?.withAlpha((255 * 0.8).round()),
                ),
              ),
            ),

            // --- Sección 1: Próximo Partido ---
            _buildSectionTitle(context, 'Próximo Partido'),
            const UpcomingMatchCard(),
            const SizedBox(height: 32),

            // --- Sección 2: Estado del Equipo ---
            _buildSectionTitle(context, 'Estado del Equipo'),
            const SquadStatusCard(),
            const SizedBox(height: 32),

            // --- Sección 3: Clasificación ---
            _buildSectionTitle(context, 'Clasificación'),
            const LiveStandingsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget helper para los títulos de sección, manteniendo la consistencia
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.robotoCondensed(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
        ),
      ),
    );
  }
}
