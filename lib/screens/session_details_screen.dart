import 'package:flutter/material.dart';
import 'package:myapp/models/training_session.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/screens/drill_selection_screen.dart';
import 'package:myapp/services/session_service.dart';

class SessionDetailsScreen extends StatefulWidget {
  final DateTime date;
  final List<TrainingSession> sessions;

  const SessionDetailsScreen({
    super.key,
    required this.date,
    required this.sessions,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final SessionService _sessionService = SessionService();
  late List<TrainingSession> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.sessions;
  }

  Future<void> _addDrillsToSession(int sessionIndex, List<Drill> drills) async {
    setState(() {
      _sessions[sessionIndex].drills.addAll(drills);
    });
    await _sessionService.updateSession(_sessions[sessionIndex]);
  }

  Future<void> _removeDrillFromSession(int sessionIndex, Drill drill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${drill.title}" de esta sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _sessions[sessionIndex].drills.remove(drill);
      });
      await _sessionService.updateSession(_sessions[sessionIndex]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${drill.title}" eliminado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sesiones para ${DateFormat.yMMMEd().format(widget.date)}'),
      ),
      body: _sessions.isEmpty
          ? const Center(
              child: Text('No hay sesiones programadas para este día.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(session.title, style: Theme.of(context).textTheme.titleLarge),
                          subtitle: Text(session.objective, style: Theme.of(context).textTheme.titleMedium),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 30),
                            onPressed: () async {
                              final selectedDrills = await Navigator.push<List<Drill>>(
                                context,
                                MaterialPageRoute(builder: (context) => const DrillSelectionScreen()),
                              );
                              if (selectedDrills != null && selectedDrills.isNotEmpty) {
                                await _addDrillsToSession(index, selectedDrills);
                              }
                            },
                          ),
                        ),
                        const Divider(),
                        if (session.drills.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('Aún no hay ejercicios en esta sesión.')),
                          )
                        else
                          ...session.drills.map((drill) => Dismissible(
                                key: ValueKey(drill.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _removeDrillFromSession(index, drill),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                                  title: Text(drill.title),
                                  subtitle: Text(drill.category),
                                ),
                              )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
