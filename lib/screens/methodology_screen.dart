
import 'package:flutter/material.dart';
import 'package:myapp/data/drill_data.dart'; // Usamos la lista unificada
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/widgets/drill_card.dart';

class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filtramos la lista principal para obtener los ejercicios de cada categoría.
    final defensive = allDrills.where((d) => d.category == 'Defensa').toList();
    final offensive = allDrills.where((d) => d.category == 'Ataque').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Methodology Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'DEFENSA'),
              Tab(text: 'ATAQUE'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Pasamos las listas filtradas a los widgets que las muestran.
            _buildDrillList(defensive),
            _buildDrillList(offensive),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Este widget ahora simplemente muestra la lista de ejercicios que recibe.
  Widget _buildDrillList(List<Drill> drills) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: drills.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          // Eliminamos el parámetro 'isFeatured' que ya no existe.
          child: DrillCard(drill: drills[index]),
        );
      },
    );
  }
}
