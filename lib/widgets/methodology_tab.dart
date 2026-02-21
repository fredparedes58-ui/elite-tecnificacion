import 'package:flutter/material.dart';

class MethodologyTab extends StatelessWidget {
  const MethodologyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuestra Metodología')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              context,
              "Filosofía de Juego",
              "Nuestro modelo se basa en un fútbol asociativo, de posesión y con vocación ofensiva. Buscamos la superioridad numérica desde la salida de balón y la presión alta tras pérdida.",
              Icons.psychology,
            ),
            const SizedBox(height: 20),
            _section(
              context,
              "Principios Ofensivos",
              "Amplitud, profundidad, movilidad constante y búsqueda del tercer hombre. Fomentamos la creatividad y el atrevimiento en el último tercio del campo.",
              Icons.sports_soccer,
            ),
            const SizedBox(height: 20),
            _section(
              context,
              "Principios Defensivos",
              "Presión organizada, repliegue intensivo, defensa zonal y máxima concentración en el balón parado. La actitud defensiva es un esfuerzo de todo el equipo.",
              Icons.shield,
            ),
            const SizedBox(height: 20),
            _section(
              context,
              "Valores",
              "Compañerismo, esfuerzo, respeto, disciplina y humildad. Formamos personas además de futbolistas.",
              Icons.groups,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 20),
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
