// ============================================================
// PANTALLA: MATCHES (Gestión de Partidos)
// ============================================================
// Muestra todos los partidos y permite registrar estadísticas
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'match_report_screen.dart';
import 'live_match_screen.dart';
import 'victory_share_screen.dart';
import '../models/player_model.dart';
import '../services/file_management_service.dart';
import '../data/ffcv_fixtures.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  String? _userRole;
  final FileManagementService _fileService = FileManagementService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userRole = response['role'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  bool get _isCoachOrAdmin => ['coach', 'admin'].contains(_userRole);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stream = Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('match_date');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'PARTIDOS & RESULTADOS',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'CALENDARIO FFCV'),
            Tab(text: 'PARTIDOS REGISTRADOS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFFCVCalendarTab(), _buildRegisteredMatchesTab(stream)],
      ),
    );
  }

  Widget _buildFFCVCalendarTab() {
    final allMatches = getAllFFCVMatches();

    // Agrupar por jornada
    final Map<int, List<FFCVMatch>> matchesByJornada = {};
    for (var match in allMatches) {
      if (!matchesByJornada.containsKey(match.jornada)) {
        matchesByJornada[match.jornada] = [];
      }
      matchesByJornada[match.jornada]!.add(match);
    }

    final sortedJornadas = matchesByJornada.keys.toList()..sort();

    if (allMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Calendario FFCV',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              'Los partidos se mostrarán aquí',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedJornadas.length,
      itemBuilder: (context, index) {
        final jornada = sortedJornadas[index];
        final matches = matchesByJornada[jornada]!;
        return _buildJornadaSection(jornada, matches);
      },
    );
  }

  Widget _buildRegisteredMatchesTab(Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                Icon(Icons.sports_soccer, size: 64, color: Colors.white24),
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
    );
  }

  Widget _buildJornadaSection(int jornada, List<FFCVMatch> matches) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de jornada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.secondary.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'JORNADA $jornada',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${matches.length} partidos',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Lista de partidos de la jornada
          ...matches.map((match) => _buildFFCVMatchCard(match, theme)),
        ],
      ),
    );
  }

  Widget _buildFFCVMatchCard(FFCVMatch match, ThemeData theme) {
    final isPlayed = match.isPlayed;
    final statusColor = isPlayed ? Colors.green : Colors.orange;
    final statusLabel = isPlayed ? 'JUGADO' : 'PROGRAMADO';
    final statusIcon = isPlayed ? Icons.check_circle : Icons.schedule;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con estado y fecha
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (match.time != null)
                  Text(
                    '${match.time}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(match.date),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Marcador
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Equipo Local
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.homeTeam,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.isPlayed && match.homeGoals != null
                              ? match.homeGoals!.toString()
                              : '-',
                          style: GoogleFonts.oswald(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // VS / Resultado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    match.isPlayed ? match.score! : 'VS',
                    style: GoogleFonts.oswald(
                      fontSize: match.isPlayed ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: match.isPlayed ? Colors.white : Colors.white38,
                      letterSpacing: match.isPlayed ? 0 : 2,
                    ),
                  ),
                ),

                // Equipo Visitante
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.awayTeam,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.isPlayed && match.awayGoals != null
                              ? match.awayGoals!.toString()
                              : '-',
                          style: GoogleFonts.oswald(
                            fontSize: 24,
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

          // Información adicional (ubicación)
          if (match.location.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.location,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.field != null)
                    Text(
                      match.field!,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                ],
              ),
            ),
        ],
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
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.1),
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

          // Botones de acción según el estado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildActionButtons(context, match, status),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> match,
    String status,
  ) {
    if (status == 'FINISHED') {
      // Partido finalizado: botones de acción
      return Column(
        children: [
          // Botón principal: Registrar estadísticas
          SizedBox(
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
          const SizedBox(height: 12),
          // Fila de botones secundarios: Viralizar e Informe AI
          Row(
            children: [
              // Botón Viralizar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleVictoryShare(context),
                  icon: const Icon(Icons.rocket_launch, size: 20),
                  label: Text(
                    'VIRALIZAR',
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Informe AI (solo para coaches/admins)
              if (_isCoachOrAdmin)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _openMatchReport(context, match);
                    },
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: Text(
                      'INFORME AI',
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    } else if (status == 'LIVE' || status == 'PENDING') {
      // Partido próximo o en vivo: iniciar modo Live
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final matchId = match['id'] as String;
            final teamId = match['team_id'] as String? ?? 'demo-team-id';
            final awayTeam = match['team_away'] as String?;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveMatchScreen(
                  matchId: matchId,
                  teamId: teamId,
                  opponentName: awayTeam,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_circle_filled, size: 24),
          label: Text(
            'MODO LIVE',
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
        'Dic',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Maneja el flujo de viralización: seleccionar imagen y navegar a VictoryShareScreen
  Future<void> _handleVictoryShare(BuildContext context) async {
    // Mostrar diálogo para seleccionar fuente de imagen
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar Foto'),
                subtitle: const Text('Usar cámara del dispositivo'),
                onTap: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final image = await _fileService.pickImageFromCamera();
                  if (image != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VictoryShareScreen(imageFile: image),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Galería'),
                subtitle: const Text('Seleccionar de galería'),
                onTap: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final image = await _fileService.pickImageFromGallery();
                  if (image != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VictoryShareScreen(imageFile: image),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.orange),
                title: const Text('Explorador de Archivos'),
                subtitle: const Text('PC, iCloud, Google Drive'),
                onTap: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final image = await _fileService.pickFile(
                    type: FileType.image,
                  );
                  if (image != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VictoryShareScreen(imageFile: image),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<List<Player>> _getConvocatedPlayers(String teamId) async {
    try {
      // Obtener jugadores del equipo con match_status de 'starter' o 'sub'
      final response = await Supabase.instance.client
          .from('team_members')
          .select('*, profiles(*)')
          .eq('team_id', teamId)
          .eq('role', 'player')
          .or('match_status.eq.starter,match_status.eq.sub');

      final playersData = List<Map<String, dynamic>>.from(response);

      // Convertir a objetos Player
      final players = playersData.map((data) {
        // Mapear los datos de team_members y profiles a formato Player
        final profile = data['profiles'] as Map<String, dynamic>?;
        final name =
            profile?['full_name'] as String? ??
            data['user_id'] as String? ??
            'Jugador';
        final image =
            profile?['avatar_url'] as String? ?? 'assets/players/default.png';

        return Player(
          id: data['user_id'] as String?,
          name: name,
          role: data['position'] as String?,
          isStarter: (data['match_status'] as String?) == 'starter',
          image: image,
          matchStatus: data['match_status'] == 'starter'
              ? MatchStatus.starter
              : MatchStatus.sub,
          statusNote: data['status_note'] as String?,
          number: data['number'] as int?,
        );
      }).toList();

      return players;
    } catch (e) {
      debugPrint('Error obteniendo jugadores convocados: $e');
      return [];
    }
  }

  Future<void> _openMatchReport(
    BuildContext context,
    Map<String, dynamic> match,
  ) async {
    // Obtener los jugadores convocados del partido desde Supabase
    final teamId = match['team_id'] as String? ?? 'demo-team-id';
    final convocatedPlayers = await _getConvocatedPlayers(teamId);

    // Si no hay jugadores convocados, usar lista vacía
    if (convocatedPlayers.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ No hay jugadores convocados para este partido',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    if (!context.mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchReportScreen(
          matchId: match['id'] as String,
          teamId: teamId,
          convocatedPlayers: convocatedPlayers,
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
