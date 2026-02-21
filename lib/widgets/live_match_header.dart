import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveMatchHeader extends StatelessWidget {
  final String partidoId; // El ID del partido que estamos viendo

  const LiveMatchHeader({super.key, required this.partidoId});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder es el widget que "escucha" a la base de datos
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('partidos')
          .stream(primaryKey: ['id']) // Clave primaria necesaria para streams
          .eq('id', partidoId), // Filtramos solo ESTE partido
      builder: (context, snapshot) {
        // 1. Manejo de estados de carga y error
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Esperando datos..."));
        }

        // 2. Extraemos los datos frescos
        final partido = snapshot.data![0];
        final golesLocal = partido['goles_local'];
        final golesVisitante = partido['goles_visitante'];
        final minuto = partido['minuto_actual'];
        final estado = partido['estado']; // 'EN_JUEGO', etc.

        // 3. Pintamos el Marcador
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87, // Fondo oscuro estilo pro
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Estado y Minuto
              Text(
                estado == 'EN_JUEGO' ? "$minuto'" : estado,
                style: const TextStyle(
                  color: Colors.greenAccent, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // LOCAL
                  _EquipoColumn(nombre: partido['local_nombre'], goles: golesLocal),
                  
                  // VS / GUIÓN
                  const Text("-", style: TextStyle(fontSize: 30, color: Colors.white)),
                  
                  // VISITANTE
                  _EquipoColumn(nombre: partido['visitante_nombre'], goles: golesVisitante),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget auxiliar para no repetir código
class _EquipoColumn extends StatelessWidget {
  final String nombre;
  final int goles;

  const _EquipoColumn({required this.nombre, required this.goles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          goles.toString(),
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          nombre,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}