import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/widgets/radar_chart.dart';

class PlayerProfileScreen extends StatelessWidget {
  final Player player = Player(
    name: 'Leo Messi',
    number: '#10',
    level: 12,
    position1: 'Canonero',
    position2: 'Muralla',
    avatarAsset: 'assets/messi.png', // Placeholder
    stats: PlayerStats(
      media: 88,
      pac: 85,
      sho: 92,
      pas: 91,
      dri: 95,
      def: 38,
      phy: 65,
      goals: 32,
      asst: 12,
    ),
  );

  final List<String> statLabels = ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];

  PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(player.name.toUpperCase(), style: textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(player.number, style: textTheme.headlineMedium?.copyWith(color: colors.primary)),
            const SizedBox(height: 24),
            _buildPlayerCard(context),
            const SizedBox(height: 24),
            _buildStatsRadar(),
            const SizedBox(height: 16),
            _buildStatsSummary(context),
            const SizedBox(height: 32),
            _buildHighlights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Image.network(
                'https://crests.football-data.org/crests/5.png',
                height: 200,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('NIVEL ${player.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPositionChip(player.position1, Colors.red, context),
              _buildPositionChip(player.position2, Colors.blue, context),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPositionChip(String label, Color color, BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsRadar() {
    return SizedBox(
      width: 250,
      height: 250,
      child: RadarChart(
        stats: player.stats.statsList,
        labels: statLabels,
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, 'MEDIA', player.stats.media.toString(), textTheme.headlineMedium),
        _buildStatItem(context, 'GOLES', player.stats.goals.toString(), textTheme.headlineMedium),
        _buildStatItem(context, 'ASST', player.stats.asst.toString(), textTheme.headlineMedium),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, TextStyle? style) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: style?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: textTheme.labelMedium?.copyWith(color: Colors.white70)),
      ],
    );
  }

  Widget _buildHighlights(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Momentos Destacados', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHighlightIcon(Icons.sports_soccer, 'Goles'),
            _buildHighlightIcon(Icons.directions_run, 'Jugadas'),
            _buildHighlightIcon(Icons.shield, 'Equipo'),
            _buildHighlightIcon(Icons.star, 'Clase'),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF2A2A2A),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
