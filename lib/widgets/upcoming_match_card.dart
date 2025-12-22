import 'package:flutter/material.dart';

class UpcomingMatchCard extends StatelessWidget {
  const UpcomingMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage('https://img.freepik.com/free-photo/soccer-field-painted-white-lines-green-grass-stadium_124507-15631.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('UPCOMING MATCH', style: textTheme.labelMedium?.copyWith(color: Colors.yellow)),
                  IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 16),
              Text('VS. ROBO-UNITED', style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Stadium 2030 | vs El Fariolen', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('84', 'WINS', Colors.green, context),
                  _buildStatColumn('23', 'TIED', Colors.yellow, context),
                  _buildStatColumn('10', 'LOST', Colors.red, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
      ],
    );
  }
}
