
import 'package:flutter/material.dart';
import 'package:myapp/models/drill_model.dart';

class DrillDetailsScreen extends StatelessWidget {
  final Drill drill;

  const DrillDetailsScreen({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(drill.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero(
            //   tag: 'drill-image-${drill.id}',
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(15.0),
            //     // child: Image.network(
            //     //   drill.image,
            //     //   fit: BoxFit.cover,
            //     //   width: double.infinity,
            //     //   height: 250,
            //     // ),
            //   ),
            // ),
            const SizedBox(height: 24),
            Text(
              'Detalles del Ejercicio',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, Icons.category, 'Categoría', drill.category),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.star, 'Dificultad', drill.difficulty),
            const SizedBox(height: 24),
            Text(
              'Objetivos',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              drill.description, 
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.secondary, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.titleMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
