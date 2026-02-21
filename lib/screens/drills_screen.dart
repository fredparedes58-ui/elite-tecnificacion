import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/drill_card.dart';
import 'package:myapp/widgets/empty_state_widget.dart';
import 'package:myapp/widgets/error_state_widget.dart';
import 'package:myapp/widgets/loading_widget.dart';
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
      debugPrint('Error cargando ejercicios: $e');
      // Retornar lista vacía en lugar de lanzar excepción para mejor UX
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'Biblioteca de Ejercicios',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _drillsFuture,
        builder: (context, snapshot) {
          // 1. Mientras se cargan los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Cargando ejercicios...');
          }

          // 2. Si ocurre un error
          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Error al cargar ejercicios',
              message: 'Asegúrate de que la tabla "drills" existe en tu base de datos de Supabase y que la app tiene los permisos correctos.',
              actionLabel: 'Reintentar',
              onAction: () {
                setState(() {
                  _drillsFuture = _fetchDrills();
                });
              },
            );
          }

          // 3. Si la tabla está vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center_outlined,
              title: 'No hay ejercicios disponibles',
              subtitle: 'Los ejercicios aparecerán aquí una vez que se agreguen a la base de datos',
            );
          }

          // 4. Si todo fue exitoso, muestra la lista con RefreshIndicator
          final drills = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _drillsFuture = _fetchDrills();
              });
            },
            child: ListView.builder(
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
            ),
          );
        },
      ),
      ),
    );
  }
}
