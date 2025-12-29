import 'package:flutter/material.dart';

class DrillCard extends StatelessWidget {
  final Map<String, dynamic> drill;
  final VoidCallback onTap;

  const DrillCard({super.key, required this.drill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drill['name'] ?? 'Ejercicio sin nombre',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                drill['description'] ?? 'Sin descripción.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text("${drill['duration_minutes']} min"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(drill['category'] ?? 'General'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
