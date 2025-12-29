import 'package:flutter/material.dart';

class DrillDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> drill;

  const DrillDetailsScreen({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drill['name'] ?? 'Detalles del Ejercicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drill['name'] ?? 'Ejercicio sin nombre',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.category_outlined, 'Categoría', drill['category'] ?? 'General'),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.timer_outlined, 'Duración', "${drill['duration_minutes']} minutos"),
            const SizedBox(height: 24),

            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              drill['description'] ?? 'No hay descripción disponible.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            Text(
              'Instrucciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              drill['instructions'] ?? 'No hay instrucciones disponibles.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // Aquí podrías añadir más detalles, como un vídeo o una imagen del ejercicio.
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text(value),
      ],
    );
  }
}
