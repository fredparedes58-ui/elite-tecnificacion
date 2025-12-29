import 'package:flutter/material.dart';
import 'package:myapp/models/player_stats.dart';
import 'package:myapp/widgets/stat_box.dart';

class PlayerStatsCard extends StatelessWidget {
  final PlayerStats stats;

  const PlayerStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estadísticas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatBox(title: 'Goles', value: stats.goals.toString()),
                StatBox(title: 'Asistencias', value: stats.assists.toString()),
                StatBox(title: 'Partidos', value: stats.matchesPlayed.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
