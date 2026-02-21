import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/data/league_data.dart';
import 'package:myapp/models/league_model.dart';

class LiveStandingsCard extends StatelessWidget {
  const LiveStandingsCard({super.key});

  // Nombre del equipo a destacar (equipo del usuario)
  static const String _highlightedTeam = "C.F. Fundació VCF 'A'";

  @override
  Widget build(BuildContext context) {
    // Mostramos todos los equipos
    final allTeams = leagueTable.toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A), // Fondo oscuro de la card
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: LIVE STANDINGS
          Text(
            'LIVE STANDINGS',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Tabla con scroll horizontal si es necesario
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 72, // Ancho mínimo
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Headers
                  _buildTableHeader(),
                  const SizedBox(height: 8),
                  // Separador visual
                  Container(
                    height: 1,
                    color: Colors.grey.shade700,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  // Standings Rows - Todos los equipos
                  ...allTeams.map((team) {
                    final isHighlighted = team.club == _highlightedTeam;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: _buildStandingRow(team, isHighlighted),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '#',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 140,
          child: Text(
            'TEAM',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            'J',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            'G',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            'E',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            'P',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'GF',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'GC',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            'DIF',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            'PT',
            textAlign: TextAlign.right,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandingRow(TeamStanding team, bool isHighlighted) {
    // Determinar color del punto según la posición
    Color dotColor;
    if (team.position <= 3) {
      dotColor = const Color(0xFFFFD700); // Amarillo para top 3
    } else if (team.position <= 6) {
      dotColor = Colors.blue; // Azul para posiciones 4-6
    } else {
      dotColor = Colors.grey.shade400; // Gris para el resto
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFD700).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              team.position.toString(),
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Escudo del equipo
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(50),
                  Colors.white.withAlpha(30),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(80),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _getTeamInitials(team.club),
                style: GoogleFonts.robotoCondensed(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              _getShortTeamName(team.club),
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              team.games.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              team.wins.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade300,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              team.draws.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.yellow.shade300,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              team.losses.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade300,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              team.goalsFor.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              team.goalsAgainst.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              team.goalDifference >= 0 ? '+${team.goalDifference}' : team.goalDifference.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: team.goalDifference >= 0 ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              team.points.toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
    if (short.length > 18) {
      final parts = short.split(' ');
      if (parts.length > 2) {
        return '${parts[0]} ${parts[1]}';
      }
    }
    
    return short;
  }
}
