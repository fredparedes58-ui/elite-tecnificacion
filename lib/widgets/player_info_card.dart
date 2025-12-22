import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';

class PlayerInfoCard extends StatelessWidget {
  final Player player;

  const PlayerInfoCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Player Info', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Name: ${player.name}'),
            Text('Position: ${player.role.toString().split('.').last}'),
          ],
        ),
      ),
    );
  }
}
