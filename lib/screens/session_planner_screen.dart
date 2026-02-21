import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/models/training_session.dart';
import 'package:myapp/screens/session_details_screen.dart';
import 'package:myapp/services/session_service.dart';
import 'package:myapp/services/field_service.dart';
import 'package:myapp/models/field_model.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:uuid/uuid.dart';

class SessionPlannerScreen extends StatefulWidget {
  const SessionPlannerScreen({super.key});

  @override
  State<SessionPlannerScreen> createState() => _SessionPlannerScreenState();
}

class _SessionPlannerScreenState extends State<SessionPlannerScreen> {
  final SessionService _sessionService = SessionService();
  final FieldService _fieldService = FieldService();
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
    TimeOfDay startTime = const TimeOfDay(hour: 16, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    List<Field> availableFields = [];
    Field? selectedField;
    bool isCheckingFields = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Sesión de Entrenamiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    icon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objectiveController,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo',
                    icon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Horario y Campo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Inicio', style: TextStyle(fontSize: 12)),
                        subtitle: Text(startTime.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startTime = picked;
                              availableFields = [];
                              selectedField = null;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Fin', style: TextStyle(fontSize: 12)),
                        subtitle: Text(endTime.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              endTime = picked;
                              availableFields = [];
                              selectedField = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isCheckingFields
                      ? null
                      : () async {
                          setDialogState(() => isCheckingFields = true);

                          final startDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            startTime.hour,
                            startTime.minute,
                          );

                          final endDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            endTime.hour,
                            endTime.minute,
                          );

                          if (endDateTime.isBefore(startDateTime) ||
                              endDateTime.isAtSameMomentAs(startDateTime)) {
                            setDialogState(() => isCheckingFields = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ La hora de fin debe ser posterior a la de inicio'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final fields = await _fieldService.getAvailableFields(
                            startTime: startDateTime,
                            endTime: endDateTime,
                          );

                          setDialogState(() {
                            availableFields = fields;
                            isCheckingFields = false;
                          });
                        },
                  icon: isCheckingFields
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(isCheckingFields
                      ? 'Verificando...'
                      : 'Verificar Disponibilidad'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
                if (availableFields.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Campos Disponibles:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  RadioGroup<Field>(
                    groupValue: selectedField,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedField = value;
                      });
                    },
                    child: Column(
                      children: availableFields.map((field) => RadioListTile<Field>(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(field.name, style: const TextStyle(fontSize: 13)),
                            subtitle: Text('${field.type} • ${field.location ?? ""}',
                                style: const TextStyle(fontSize: 11)),
                            value: field,
                          )).toList(),
                    ),
                  ),
                ] else if (availableFields.isEmpty && !isCheckingFields) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No hay campos disponibles en este horario',
                            style: TextStyle(fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ Ingresa un título')),
                  );
                  return;
                }

                if (availableFields.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Verifica la disponibilidad de campos primero'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (selectedField == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Selecciona un campo disponible'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validación final de conflictos antes de guardar
                final startDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  startTime.hour,
                  startTime.minute,
                );

                final endDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  endTime.hour,
                  endTime.minute,
                );

                final conflictCheck = await _fieldService.checkBookingConflict(
                  fieldId: selectedField!.id,
                  startTime: startDateTime,
                  endTime: endDateTime,
                );

                if (conflictCheck['hasConflict'] == true) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '❌ CONFLICTO: Ya existe "${conflictCheck['conflictingTitle']}" en ese horario',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Crear la reserva del campo
                final bookingResult = await _fieldService.createBooking(
                  fieldId: selectedField!.id,
                  teamId: 'TEAM_ID_TEMPORAL', // Aquí deberías usar el ID real del equipo
                  startTime: startDateTime,
                  endTime: endDateTime,
                  purpose: 'training',
                  title: titleController.text,
                  description: objectiveController.text,
                );

                if (context.mounted) {
                  if (bookingResult['success']) {
                    final navigator = Navigator.of(context);
                    await _handleAddNewSession(
                      titleController.text,
                      objectiveController.text,
                      date,
                    );
                    navigator.pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Sesión creada y campo reservado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(bookingResult['message'] ?? 'Error al reservar campo'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
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
      appBar: buildAppBarWithBack(
        context,
        title: const Text('Planificador de Sesiones'),
      ),
      body: SafeArea(
        child: Column(
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