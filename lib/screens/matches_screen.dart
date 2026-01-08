// ============================================================
// PANTALLA: MATCHES (Gestión de Partidos)
// ============================================================
// Muestra todos los partidos y permite registrar estadísticas
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'match_report_screen.dart';
import '../models/player_model.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('match_date');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'PARTIDOS',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.roboto(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay partidos registrados',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildMatchCard(context, match);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    final status = match['status'] ?? 'PENDING';
    String displayStatus;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'FINISHED':
        displayStatus = 'FINAL';
        statusColor = Colors.red;
        statusIcon = Icons.check_circle;
        break;
      case 'LIVE':
        displayStatus = 'VIVO';
        statusColor = Colors.green;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'PENDING':
        displayStatus = 'PROGRAMADO';
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        displayStatus = status;
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    final homeTeam = match['team_home'] ?? 'Equipo Local';
    final awayTeam = match['team_away'] ?? 'Equipo Visitante';
    final goalsHome = match['goals_home'] ?? 0;
    final goalsAway = match['goals_away'] ?? 0;
    final matchDate = match['match_date'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  displayStatus,
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (matchDate != null)
                  Text(
                    _formatDate(matchDate),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),

          // Marcador
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Equipo Local
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          goalsHome.toString(),
                          style: GoogleFonts.oswald(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                // Equipo Visitante
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          goalsAway.toString(),
                          style: GoogleFonts.oswald(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón de acción (solo para partidos finalizados)
          if (status == 'FINISHED')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _openMatchReport(context, match);
                  },
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: Text(
                    'REGISTRAR ESTADÍSTICAS',
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openMatchReport(
    BuildContext context,
    Map<String, dynamic> match,
  ) async {
    // TODO: Obtener los jugadores convocados del partido desde Supabase
    // Por ahora, creamos una lista demo
    final List<Player> demoPlayers = [
      Player(
        id: 'demo-player-1',
        name: 'Juan Pérez',
        role: 'Delantero',
        isStarter: true,
        image: 'assets/players/default.png',
      ),
      Player(
        id: 'demo-player-2',
        name: 'Pedro Rodríguez',
        role: 'Mediocampista',
        isStarter: true,
        image: 'assets/players/default.png',
      ),
      Player(
        id: 'demo-player-3',
        name: 'Carlos García',
        role: 'Delantero',
        isStarter: true,
        image: 'assets/players/default.png',
      ),
    ];

    // Navegar a la pantalla de reporte
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchReportScreen(
          matchId: match['id'] as String,
          teamId: 'demo-team-id', // TODO: Obtener del contexto
          convocatedPlayers: demoPlayers,
        ),
      ),
    );

    // Si se guardaron cambios, mostrar confirmación
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Estadísticas registradas correctamente',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
