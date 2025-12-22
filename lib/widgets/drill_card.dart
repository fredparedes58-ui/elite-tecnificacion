import 'package:flutter/material.dart';
import 'package:myapp/models/drill_model.dart';

class DrillCard extends StatelessWidget {
  final Drill drill;
  final bool isFeatured;

  const DrillCard({super.key, required this.drill, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isFeatured ? colors.surface : colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFeatured)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  drill.imagePath,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (isFeatured) const SizedBox(height: 16),
            Text(
              drill.category.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 4),
            Text(drill.title, style: textTheme.titleLarge),
            if (isFeatured)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(drill.description, style: textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoPill(
                  context,
                  icon: Icons.flash_on,
                  label: 'Intensidad',
                  value: drill.intensity.name,
                  color: _getIntensityColor(drill.intensity, colors),
                ),
                _buildInfoPill(context, label: 'Jugadores', value: drill.players),
                _buildInfoPill(context, label: 'Tiempo', value: drill.time),
              ],
            ),
            if (isFeatured) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('LOAD DRILL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('VIEW DETAILS'),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(BuildContext context, {
    IconData? icon,
    required String label,
  required String value,
    Color? color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null)
              Icon(icon,
                  size: 16,
                  color: color ?? colors.onSurfaceVariant),
            if (icon != null) const SizedBox(width: 4),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                  color: color ?? colors.onSurfaceVariant,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Color _getIntensityColor(DrillIntensity intensity, ColorScheme colors) {
    switch (intensity) {
      case DrillIntensity.alta:
        return Colors.red;
      case DrillIntensity.media:
        return Colors.orange;
      case DrillIntensity.baja:
        return Colors.green;
    }
  }
}
