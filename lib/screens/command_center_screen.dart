import 'package:flutter/material.dart';
import 'package:myapp/widgets/ai_prediction_card.dart';
import 'package:myapp/widgets/live_standings_card.dart';
import 'package:myapp/widgets/squad_status_card.dart';
import 'package:myapp/widgets/upcoming_match_card.dart';

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('COMMAND CENTER'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildModeSelector(context),
            const SizedBox(height: 24),
            const UpcomingMatchCard(),
            const SizedBox(height: 24),
            const LiveStandingsCard(),
            const SizedBox(height: 24),
            const SquadStatusCard(),
            const SizedBox(height: 24),
            const AIPredictionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('MÍSTER', style: TextStyle(color: Colors.white)),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {},
              child: const Text('FAMILIA', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}
