// ============================================================
// PANTALLA: MATCH REPORT (Reporte de Partido)
// ============================================================
// Permite al entrenador registrar goles, asistencias y minutos jugados
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_model.dart';
import '../models/match_stats_model.dart';
import '../services/stats_service.dart';

class MatchReportScreen extends StatefulWidget {
  final String matchId;
  final String teamId;
  final List<Player> convocatedPlayers;

  const MatchReportScreen({
    super.key,
    required this.matchId,
    required this.teamId,
    required this.convocatedPlayers,
  });

  @override
  State<MatchReportScreen> createState() => _MatchReportScreenState();
}

class _MatchReportScreenState extends State<MatchReportScreen> {
  final StatsService _statsService = StatsService();

  // Mapa para almacenar las estadísticas de cada jugador
  Map<String, PlayerStatsInput> playerStats = {};
  bool isLoading = true;
  bool isSaving = false;
  bool isGeneratingGuru = false;

  @override
  void initState() {
    super.initState();
    _initializeStats();
  }

  Future<void> _initializeStats() async {
    // Inicializar con los jugadores convocados
    for (var player in widget.convocatedPlayers) {
      playerStats[player.id ?? ''] = PlayerStatsInput(
        playerId: player.id ?? '',
        playerName: player.name,
        image: player.image,
        role: player.role,
      );
    }

    // Cargar estadísticas existentes si ya se registraron
    final existingStats = await _statsService.getMatchStats(widget.matchId);

    for (var stat in existingStats) {
      if (playerStats.containsKey(stat.playerId)) {
        playerStats[stat.playerId]!.goals = stat.goals;
        playerStats[stat.playerId]!.assists = stat.assists;
        playerStats[stat.playerId]!.minutesPlayed = stat.minutesPlayed;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveStats() async {
    setState(() {
      isSaving = true;
    });

    try {
      // Preparar datos para guardar
      final List<Map<String, dynamic>> statsToSave = playerStats.values
          .map(
            (stat) => stat.toMatchStats(
              matchId: widget.matchId,
              teamId: widget.teamId,
            ),
          )
          .toList();

      final success = await _statsService.saveMatchStats(
        matchId: widget.matchId,
        teamId: widget.teamId,
        playersStats: statsToSave,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Estadísticas guardadas correctamente',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar cambios
        }
      } else {
        throw Exception('Error al guardar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al guardar estadísticas: $e',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'REPORTE DE PARTIDO',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con instrucciones
                _buildHeader(),

                // Lista de jugadores
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.convocatedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = widget.convocatedPlayers[index];
                      final stats = playerStats[player.id]!;

                      return _buildPlayerStatsCard(player, stats);
                    },
                  ),
                ),

                // Botones de acción
                _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.edit_note, color: Colors.blue, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registra las Estadísticas',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa goles y asistencias',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(Player player, PlayerStatsInput stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header del jugador
          Row(
            children: [
              // Foto del jugador
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.3),
                backgroundImage: player.image.startsWith('http')
                    ? NetworkImage(player.image)
                    : null,
                child: !player.image.startsWith('http')
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Nombre y número
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (player.role != null)
                      Text(
                        player.role!,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contadores de estadísticas
          Row(
            children: [
              // Goles
              Expanded(
                child: _buildStatCounter(
                  label: 'Goles',
                  icon: Icons.sports_soccer,
                  color: Colors.green,
                  value: stats.goals,
                  onIncrement: () {
                    setState(() {
                      stats.goals++;
                    });
                  },
                  onDecrement: () {
                    setState(() {
                      if (stats.goals > 0) stats.goals--;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Asistencias
              Expanded(
                child: _buildStatCounter(
                  label: 'Asist.',
                  icon: Icons.support_agent,
                  color: Colors.blue,
                  value: stats.assists,
                  onIncrement: () {
                    setState(() {
                      stats.assists++;
                    });
                  },
                  onDecrement: () {
                    setState(() {
                      if (stats.assists > 0) stats.assists--;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Minutos jugados
              Expanded(
                child: _buildStatCounter(
                  label: 'Minutos',
                  icon: Icons.timer,
                  color: Colors.orange,
                  value: stats.minutesPlayed,
                  onIncrement: () {
                    setState(() {
                      if (stats.minutesPlayed < 120) {
                        stats.minutesPlayed += 5;
                      }
                    });
                  },
                  onDecrement: () {
                    setState(() {
                      if (stats.minutesPlayed >= 5) {
                        stats.minutesPlayed -= 5;
                      }
                    });
                  },
                  stepValue: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter({
    required String label,
    required IconData icon,
    required Color color,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    int stepValue = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: color,
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDecrement,
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: color,
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Botón Guardar Estadísticas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'GUARDAR ESTADÍSTICAS',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón GURU GURU (Generar Informes con Gemini)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isGeneratingGuru ? null : _generateGuruReports,
                icon: isGeneratingGuru
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 24),
                label: Text(
                  'GURU GURU',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateGuruReports() async {
    setState(() {
      isGeneratingGuru = true;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'generate_match_report_gemini',
        body: {'match_id': widget.matchId},
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Informes generados correctamente con Gemini AI',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Error desconocido';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al generar informes: $e',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingGuru = false;
        });
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Ayuda - Reporte de Partido',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.sports_soccer,
              color: Colors.green,
              text: 'Goles: Usa +/- para contar los goles de cada jugador',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.support_agent,
              color: Colors.blue,
              text: 'Asistencias: Registra las asistencias realizadas',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.timer,
              color: Colors.orange,
              text: 'Minutos: Se incrementan de 5 en 5 (máx. 120)',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.save,
              color: Colors.purple,
              text: 'Los datos se guardan automáticamente en Supabase',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDIDO',
              style: GoogleFonts.oswald(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(fontSize: 13, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
