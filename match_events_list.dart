import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchEventsList extends StatelessWidget {
  final String partidoId;

  const MatchEventsList({super.key, required this.partidoId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('eventos_partido')
          .stream(primaryKey: ['id'])
          .eq('partido_id', partidoId)
          .order('minuto', ascending: false), // Lo más nuevo arriba
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final eventos = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true, // Importante si está dentro de otro scroll
          physics: const NeverScrollableScrollPhysics(),
          itemCount: eventos.length,
          itemBuilder: (context, index) {
            final evento = eventos[index];
            return ListTile(
              leading: Text("${evento['minuto']}'", style: const TextStyle(fontWeight: FontWeight.bold)),
              title: Text(evento['jugador_nombre']),
              subtitle: Text(evento['tipo']), // 'GOL', 'TARJETA', etc.
              trailing: Icon(
                evento['tipo'] == 'GOL' ? Icons.sports_soccer : Icons.sticky_note_2,
                color: evento['tipo'] == 'GOL' ? Colors.green : Colors.yellow,
              ),
            );
          },
        );
      },
    );
  }
}