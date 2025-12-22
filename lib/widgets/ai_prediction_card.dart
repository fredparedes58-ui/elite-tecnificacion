import 'package:flutter/material.dart';

class AIPredictionCard extends StatelessWidget {
  const AIPredictionCard({super.key});

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI PREDICTION', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                IconButton(icon: const Icon(Icons.psychology, color: Colors.blue), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(value: 0.7, strokeWidth: 8),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.shuffle, color: Colors.white70), onPressed: () {}),
                IconButton(icon: const Icon(Icons.show_chart, color: Colors.white70), onPressed: () {}),
                IconButton(icon: const Icon(Icons.grid_view, color: Colors.white70), onPressed: () {}),
                IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
