import 'package:flutter/material.dart';
import 'package:myapp/data/drill_data.dart';
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/screens/drill_details_screen.dart';
import 'package:myapp/widgets/drill_card.dart';

// 1. Convertido a StatefulWidget para manejar el estado del rol
class MethodologyScreen extends StatefulWidget {
  const MethodologyScreen({super.key});

  @override
  State<MethodologyScreen> createState() => _MethodologyScreenState();
}

class _MethodologyScreenState extends State<MethodologyScreen> {
  // Variable de estado para guardar el rol actual
  String _currentRole = 'familiar'; // Rol por defecto

  @override
  Widget build(BuildContext context) {
    final defensive = allDrills.where((d) => d.category == 'Defensa').toList();
    final offensive = allDrills.where((d) => d.category == 'Ataque').toList();
    final bool isCoach = _currentRole == 'entrenador';

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
            // 2. Botón para cambiar de rol
            TextButton(
              onPressed: () {
                // Lógica para cambiar el rol con setState
                setState(() {
                  _currentRole = isCoach ? 'familiar' : 'entrenador';
                });
              },
              child: Text(
                isCoach ? 'Cambiar a Familiar' : 'Cambiar a Entrenador',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildDrillList(context, defensive),
            _buildDrillList(context, offensive),
          ],
        ),
        // 3. Mostrar el botón flotante solo si el rol es 'entrenador'
        floatingActionButton: isCoach
            ? FloatingActionButton(
                onPressed: () {
                  // Lógica futura para añadir un ejercicio
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Acción solo para entrenadores')),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null, // No mostrar el botón si no es entrenador
      ),
    );
  }

  Widget _buildDrillList(BuildContext context, List<Drill> drills) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: drills.length,
      itemBuilder: (context, index) {
        final drill = drills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DrillCard(
            drill: drill.toMap(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DrillDetailsScreen(drill: drill.toMap()),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
