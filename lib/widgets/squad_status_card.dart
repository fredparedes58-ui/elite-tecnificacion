
import 'package:flutter/material.dart';
import 'package:myapp/models/team_model.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/widgets/player_stat_card.dart'; // Importamos el nuevo widget

class SquadStatusCard extends StatefulWidget {
  const SquadStatusCard({super.key});

  @override
  State<SquadStatusCard> createState() => _SquadStatusCardState();
}

class _SquadStatusCardState extends State<SquadStatusCard> {
  late Future<Team?> _teamFuture;

  @override
  void initState() {
    super.initState();
    // Seguimos cargando los datos del equipo al iniciar
    _teamFuture = DataService().getTeamByName("C.F. Fundació VCF 'A'");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent, // Hacemos la tarjeta contenedora transparente
      child: FutureBuilder<Team?>(
        future: _teamFuture,
        builder: (context, snapshot) {
          // Manejo de estados de carga y error
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos del equipo.'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se encontró el equipo.'));
          }

          final team = snapshot.data!;
          // Filtramos y limitamos la cantidad de jugadores a mostrar para una UI limpia
          final displayPlayers = team.players.where((p) => p.isStarter).take(5).toList();

          // Construimos la lista vertical de PlayerStatCard
          return ListView.builder(
            itemCount: displayPlayers.length,
            shrinkWrap: true, // Esencial para que el ListView funcione dentro de un SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Deshabilitamos el scroll propio del ListView
            itemBuilder: (context, index) {
              return PlayerStatCard(player: displayPlayers[index]);
            },
          );
        },
      ),
    );
  }
}
