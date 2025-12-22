import 'package:flutter/material.dart';
import 'package:myapp/data/league_data.dart';

class LiveStandingsCard extends StatelessWidget {
  const LiveStandingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LIVE STANDINGS', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                TextButton(onPressed: () {}, child: const Text('VIEW ALL')),
              ],
            ),
            const SizedBox(height: 16),
            _buildStandingsTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsTable(BuildContext context) {
    return Column(
      children: leagueTable.take(3).map((team) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(team.position.toString(), style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 16),
              Image.network(team.logoUrl!, height: 24, width: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(team.club, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Text(team.points.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
