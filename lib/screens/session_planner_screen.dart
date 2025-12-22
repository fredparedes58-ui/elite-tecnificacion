import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/models/training_session.dart';
import 'package:myapp/screens/session_details_screen.dart';
import 'package:myapp/services/session_service.dart';
import 'package:uuid/uuid.dart';

class SessionPlannerScreen extends StatefulWidget {
  const SessionPlannerScreen({super.key});

  @override
  State<SessionPlannerScreen> createState() => _SessionPlannerScreenState();
}

class _SessionPlannerScreenState extends State<SessionPlannerScreen> {
  final SessionService _sessionService = SessionService();
  Map<DateTime, List<TrainingSession>> _sessions = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessionsList = await _sessionService.getSessions();
    final Map<DateTime, List<TrainingSession>> sessionsMap = {};
    for (var session in sessionsList) {
      final date = DateTime.utc(session.date.year, session.date.month, session.date.day);
      if (sessionsMap[date] == null) {
        sessionsMap[date] = [];
      }
      sessionsMap[date]!.add(session);
    }
    if (mounted) {
      setState(() {
        _sessions = sessionsMap;
      });
    }
  }

  List<TrainingSession> _getSessionsForDay(DateTime day) {
    return _sessions[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _handleAddNewSession(String title, String objective, DateTime date) async {
    final newSession = TrainingSession(
      id: const Uuid().v4(),
      date: date,
      title: title,
      objective: objective,
    );
    await _sessionService.addSession(newSession);
    await _loadSessions();
  }

  void _addSession(DateTime date) {
    final titleController = TextEditingController();
    final objectiveController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: objectiveController, decoration: const InputDecoration(labelText: 'Objetivo')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                // First, capture the navigator.
                final navigator = Navigator.of(context);
                await _handleAddNewSession(titleController.text, objectiveController.text, date);
                // Then, use it after the await.
                navigator.pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSession(TrainingSession session) async {
    await _sessionService.deleteSession(session.id);
    await _loadSessions();
  }

  Future<void> _deleteSession(TrainingSession session) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la sesión "${session.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleDeleteSession(session);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sesión "${session.title}" eliminada.')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificador de Sesiones'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getSessionsForDay,
             calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _selectedDay != null ? 'Sesiones para ${DateFormat.yMMMEd().format(_selectedDay!)}' : 'Selecciona un día', 
              style: Theme.of(context).textTheme.titleLarge
            ),
          ),
          Expanded(
            child: _selectedDay == null || _getSessionsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text('No hay sesiones este día.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _getSessionsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final session = _getSessionsForDay(_selectedDay!)[index];
                      return Dismissible(
                        key: ValueKey(session.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteSession(session),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          elevation: 2.0,
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: ListTile(
                            title: Text(session.title),
                            subtitle: Text(session.objective),
                            onTap: () {
                              if (_selectedDay != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SessionDetailsScreen(
                                      date: _selectedDay!,
                                      sessions: [session],
                                    ),
                                  ),
                                ).then((_) => _loadSessions());
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay != null 
        ? FloatingActionButton(
            tooltip: 'Añadir Sesión',
            onPressed: () => _addSession(_selectedDay!),
            child: const Icon(Icons.add),
          )
        : null,
    );
  }
}