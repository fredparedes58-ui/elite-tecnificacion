// ============================================================
// PANTALLA: PERFIL DEL JUGADOR CON ANÁLISIS DE VIDEO
// ============================================================
// Perfil completo del jugador con pestaña de análisis privado
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/widgets/analysis_video_list.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerProfileScreen extends StatefulWidget {
  final Player player;

  const PlayerProfileScreen({super.key, required this.player});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCoach = false;
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _attendanceStats;
  bool _loadingAttendance = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
    _loadAttendanceStats();
  }

  Future<void> _loadAttendanceStats() async {
    if (widget.player.id == null) return;
    
    setState(() => _loadingAttendance = true);
    try {
      final stats = await _supabaseService.getAttendanceRate(
        playerId: widget.player.id!,
        daysBack: 30,
      );
      if (mounted) {
        setState(() {
          _attendanceStats = stats;
          _loadingAttendance = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas de asistencia: $e');
      if (mounted) {
        setState(() => _loadingAttendance = false);
      }
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Verificar si el usuario actual es entrenador
      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _isCoach = ['coach', 'admin'].contains(response['role']);
        });
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.player.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.video_library), text: 'Análisis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PERFIL BÁSICO
          _buildProfileTab(textTheme, colorScheme),

          // TAB 2: ANÁLISIS DE VIDEO (PRIVADO)
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab(TextTheme textTheme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar del jugador
            Hero(
              tag: 'player-${widget.player.id}',
              child: CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage(widget.player.image),
                backgroundColor: colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),

            // Nombre del jugador
            Text(
              widget.player.name,
              style: GoogleFonts.oswald(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Rol del jugador (si existe)
            if (widget.player.role != null && widget.player.role!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.2),
                      colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.player.role!.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Info adicional
            if (widget.player.matchStatus != MatchStatus.unselected)
              _buildInfoCard(
                icon: Icons.assignment_outlined,
                label: 'Estado',
                value: _getMatchStatusLabel(_matchStatusToString(widget.player.matchStatus)),
                color: _getMatchStatusColor(_matchStatusToString(widget.player.matchStatus)),
              ),

            const SizedBox(height: 24),

            // Widget de Compromiso (Asistencia)
            _buildCommitmentWidget(colorScheme),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header de privacidad
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isCoach
                        ? 'Videos privados. Solo visibles para ti y el jugador.'
                        : 'Videos de análisis técnico de tu entrenador.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de videos
          Expanded(
            child: AnalysisVideoList(
              playerId: widget.player.id ?? '',
              isCoach: _isCoach,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _matchStatusToString(MatchStatus? status) {
    if (status == null) return '';
    switch (status) {
      case MatchStatus.starter:
        return 'starter';
      case MatchStatus.sub:
        return 'sub';
      case MatchStatus.unselected:
        return 'unselected';
    }
  }

  String _getMatchStatusLabel(String status) {
    switch (status) {
      case 'starter':
        return 'TITULAR';
      case 'sub':
        return 'SUPLENTE';
      case 'unselected':
        return 'NO CONVOCADO';
      default:
        return status.toUpperCase();
    }
  }

  Color _getMatchStatusColor(String status) {
    switch (status) {
      case 'starter':
        return Colors.green;
      case 'sub':
        return Colors.orange;
      case 'unselected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCommitmentWidget(ColorScheme colorScheme) {
    if (_loadingAttendance) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_attendanceStats == null) {
      return const SizedBox.shrink();
    }

    final totalSessions = _attendanceStats!['total_sessions'] as int? ?? 0;
    final presentCount = _attendanceStats!['present_count'] as int? ?? 0;
    final absentCount = _attendanceStats!['absent_count'] as int? ?? 0;
    final attendanceRate = (_attendanceStats!['attendance_rate'] as num?)?.toDouble() ?? 0.0;

    if (totalSessions == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin datos de asistencia',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aún no hay entrenamientos registrados',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.2),
            colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'COMPROMISO',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Gráfico circular
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: attendanceRate,
                            color: _getAttendanceColor(attendanceRate),
                            title: '${attendanceRate.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 100 - attendanceRate,
                            color: Colors.grey.withOpacity(0.2),
                            radius: 50,
                            title: '',
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${attendanceRate.toStringAsFixed(1)}%',
                          style: GoogleFonts.oswald(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Asistencia',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Estadísticas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      'Total Sesiones',
                      totalSessions.toString(),
                      Icons.event,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Presente',
                      presentCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Ausente',
                      absentCount.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Resumen textual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getAttendanceSummary(presentCount, absentCount, totalSessions),
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getAttendanceSummary(int present, int absent, int total) {
    if (total == 0) return 'Sin datos de asistencia';
    
    if (absent == 0) {
      return 'Asistencia perfecta: ${present} de ${total} entrenamientos';
    } else {
      return 'Ha faltado a $absent de los últimos $total entrenamientos';
    }
  }
}
