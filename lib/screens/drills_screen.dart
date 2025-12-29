import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/drill_card.dart';
import 'package:myapp/screens/drill_details_screen.dart';

class DrillsScreen extends StatefulWidget {
  const DrillsScreen({super.key});

  @override
  State<DrillsScreen> createState() => _DrillsScreenState();
}

class _DrillsScreenState extends State<DrillsScreen> {
  late final Future<List<Map<String, dynamic>>> _drillsFuture;

  @override
  void initState() {
    super.initState();
    _drillsFuture = _fetchDrills();
  }

  Future<List<Map<String, dynamic>>> _fetchDrills() async {
    try {
      // Obtenemos los datos desde la tabla 'drills' de Supabase
      final response = await Supabase.instance.client.from('drills').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Si hay un error, lo lanzamos para que el FutureBuilder lo capture
      throw Exception('Error al cargar los ejercicios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _drillsFuture,
        builder: (context, snapshot) {
          // 1. Mientras se cargan los datos, muestra un spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Si ocurre un error en la conexión o la tabla no existe
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: No se pudieron cargar los ejercicios.\n\nAsegúrate de que la tabla "drills" existe en tu base de datos de Supabase y que la app tiene los permisos correctos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          // 3. Si la tabla está vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron ejercicios.\n\nAsegúrate de haber añadido datos a la tabla "drills" en Supabase.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // 4. Si todo fue exitoso, muestra la lista
          final drills = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: drills.length,
            itemBuilder: (context, index) {
              final drill = drills[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DrillCard(
                  drill: drill,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DrillDetailsScreen(drill: drill),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
