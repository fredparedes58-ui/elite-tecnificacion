// ============================================================
// PANTALLA: TOP SCORERS (Tabla de Goleadores - Pichichi)
// ============================================================
// Muestra rankings de goleadores con 3 pestañas:
// 1. Mi Equipo
// 2. Por Categoría
// 3. Club Global
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_stats_model.dart';
import '../services/stats_service.dart';

class TopScorersScreen extends StatefulWidget {
  final String teamId;
  final String? category;
  final String clubId;

  const TopScorersScreen({
    super.key,
    required this.teamId,
    this.category,
    required this.clubId,
  });

  @override
  State<TopScorersScreen> createState() => _TopScorersScreenState();
}

class _TopScorersScreenState extends State<TopScorersScreen>
    with SingleTickerProviderStateMixin {
  final StatsService _statsService = StatsService();

  late TabController _tabController;

  List<TopScorer> teamScorers = [];
  List<TopScorer> categoryScorers = [];
  List<TopScorer> clubScorers = [];

  bool isLoadingTeam = true;
  bool isLoadingCategory = true;
  bool isLoadingClub = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRankings() async {
    // Cargar los 3 rankings en paralelo
    await Future.wait([
      _loadTeamScorers(),
      _loadCategoryScorers(),
      _loadClubScorers(),
    ]);
  }

  Future<void> _loadTeamScorers() async {
    setState(() => isLoadingTeam = true);
    try {
      final scorers = await _statsService.getTeamTopScorers(
        teamId: widget.teamId,
        limit: 10,
      );
      setState(() {
        teamScorers = scorers;
        isLoadingTeam = false;
      });
    } catch (e) {
      print('Error loading team scorers: $e');
      setState(() => isLoadingTeam = false);
    }
  }

  Future<void> _loadCategoryScorers() async {
    if (widget.category == null || widget.category!.isEmpty) {
      setState(() => isLoadingCategory = false);
      return;
    }

    setState(() => isLoadingCategory = true);
    try {
      final scorers = await _statsService.getCategoryTopScorers(
        category: widget.category!,
        clubId: widget.clubId,
        limit: 20,
      );
      setState(() {
        categoryScorers = scorers;
        isLoadingCategory = false;
      });
    } catch (e) {
      print('Error loading category scorers: $e');
      setState(() => isLoadingCategory = false);
    }
  }

  Future<void> _loadClubScorers() async {
    setState(() => isLoadingClub = true);
    try {
      final scorers = await _statsService.getClubTopScorers(
        clubId: widget.clubId,
        limit: 50,
      );
      setState(() {
        clubScorers = scorers;
        isLoadingClub = false;
      });
    } catch (e) {
      print('Error loading club scorers: $e');
      setState(() => isLoadingClub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'TABLA DE GOLEADORES',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.oswald(fontSize: 13),
          tabs: const [
            Tab(text: 'MI EQUIPO'),
            Tab(text: 'CATEGORÍA'),
            Tab(text: 'CLUB GLOBAL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Mi Equipo
          _buildRankingTab(
            scorers: teamScorers,
            isLoading: isLoadingTeam,
            emptyMessage: 'No hay goleadores registrados en tu equipo',
            onRefresh: _loadTeamScorers,
          ),

          // TAB 2: Por Categoría
          _buildRankingTab(
            scorers: categoryScorers,
            isLoading: isLoadingCategory,
            emptyMessage: widget.category != null
                ? 'No hay goleadores en la categoría ${widget.category}'
                : 'Asigna una categoría a tu equipo para ver este ranking',
            onRefresh: _loadCategoryScorers,
            showTeamName: true,
          ),

          // TAB 3: Club Global
          _buildRankingTab(
            scorers: clubScorers,
            isLoading: isLoadingClub,
            emptyMessage: 'No hay goleadores registrados en el club',
            onRefresh: _loadClubScorers,
            showTeamName: true,
            showCategory: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTab({
    required List<TopScorer> scorers,
    required bool isLoading,
    required String emptyMessage,
    required VoidCallback onRefresh,
    bool showTeamName = false,
    bool showCategory = false,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scorers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(
                'RECARGAR',
                style: GoogleFonts.oswald(letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scorers.length + 1, // +1 para el header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildRankingHeader();
          }

          final scorer = scorers[index - 1];
          final rank = index;

          return _buildScorerCard(
            scorer: scorer,
            rank: rank,
            showTeamName: showTeamName,
            showCategory: showCategory,
          );
        },
      ),
    );
  }

  Widget _buildRankingHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ranking de Goleadores',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Top Pichichis 🏆',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
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

  Widget _buildScorerCard({
    required TopScorer scorer,
    required int rank,
    bool showTeamName = false,
    bool showCategory = false,
  }) {
    // Colores especiales para el Top 3
    Color rankColor;
    Color cardBorderColor;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Oro
        cardBorderColor = const Color(0xFFFFD700).withOpacity(0.3);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Plata
        cardBorderColor = const Color(0xFFC0C0C0).withOpacity(0.3);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronce
        cardBorderColor = const Color(0xFFCD7F32).withOpacity(0.3);
        break;
      default:
        rankColor = Colors.white70;
        cardBorderColor = Colors.white.withOpacity(0.1);
    }

    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTopThree
              ? [rankColor.withOpacity(0.1), rankColor.withOpacity(0.05)]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: isTopThree ? 2 : 1),
      ),
      child: Row(
        children: [
          // Posición en el ranking
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                style: GoogleFonts.oswald(
                  fontSize: rank <= 3 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Foto del jugador
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
            backgroundImage: scorer.photoUrl != null
                ? NetworkImage(scorer.photoUrl!)
                : null,
            child: scorer.photoUrl == null
                ? Text(
                    scorer.playerName[0].toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Info del jugador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scorer.playerName,
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (scorer.jerseyNumber != null) ...[
                      Text(
                        '#${scorer.jerseyNumber}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                    if (scorer.position != null) ...[
                      Text(
                        scorer.position!,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
                if (showTeamName && scorer.teamName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    scorer.teamName!,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (showCategory && scorer.category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    scorer.category!,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Estadísticas
          Column(
            children: [
              // Goles (grande y destacado)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scorer.totalGoals.toString(),
                      style: GoogleFonts.oswald(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Asistencias y partidos
              Row(
                children: [
                  _buildMiniStat(
                    icon: Icons.support_agent,
                    value: scorer.totalAssists,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniStat(
                    icon: Icons.event,
                    value: scorer.matchesPlayed,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
