
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/data/upcoming_matches_data.dart';

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
        ),
        child: Column(
          children: [
            // Nombres de los equipos y escudos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamDisplay(nextMatch.homeTeam),
                Text(
                  'VS',
                  style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildTeamDisplay(nextMatch.awayTeam),
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
            _buildMatchInfo(nextMatch.date, '${nextMatch.time} - ${nextMatch.location}', context),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar el escudo y nombre de un equipo
  Widget _buildTeamDisplay(String teamName) {
    // Obtener las iniciales del equipo para el escudo
    final initials = _getTeamInitials(teamName);
    final shortName = _getShortTeamName(teamName);
    
    return Column(
      children: [
        // Escudo circular con iniciales del equipo
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(40),
                Colors.white.withAlpha(20),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(100),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.robotoCondensed(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          shortName.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoCondensed(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Obtener las iniciales del equipo para el escudo
  String _getTeamInitials(String teamName) {
    // Extraer las iniciales principales del nombre del equipo
    final parts = teamName.split(' ');
    if (parts.isEmpty) return 'FC';
    
    // Si el nombre tiene "C.F." o similar, usar esas iniciales
    if (teamName.contains('C.F.')) {
      return 'CF';
    } else if (teamName.contains('U.D.')) {
      return 'UD';
    } else if (parts.length >= 2) {
      // Tomar las primeras letras de las primeras dos palabras significativas
      String first = '';
      String second = '';
      for (var part in parts) {
        if (part.isNotEmpty && !part.contains('.')) {
          if (first.isEmpty) {
            first = part[0].toUpperCase();
          } else if (second.isEmpty) {
            second = part[0].toUpperCase();
            break;
          }
        }
      }
      return first + (second.isNotEmpty ? second : '');
    }
    
    return teamName.substring(0, teamName.length > 2 ? 2 : teamName.length).toUpperCase();
  }

  // Obtener un nombre corto del equipo para mostrar
  String _getShortTeamName(String teamName) {
    // Remover sufijos comunes y acortar nombres largos
    String short = teamName
        .replaceAll('C.F. ', '')
        .replaceAll('U.D. ', '')
        .replaceAll('Juvenil', 'Juv.')
        .replaceAll('Fundació', 'Fund.');
    
    // Si es muy largo, tomar solo las primeras palabras importantes
    if (short.length > 20) {
      final parts = short.split(' ');
      if (parts.length > 2) {
        return '${parts[0]} ${parts[1]}';
      }
    }
    
    return short;
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
