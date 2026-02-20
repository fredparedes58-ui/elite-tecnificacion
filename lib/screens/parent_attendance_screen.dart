// ============================================================
// PANTALLA: CONTROL DE ASISTENCIA PARA PADRES
// ============================================================
// Permite que los padres marquen asistencia entrenamiento
// por entrenamiento para sus hijos
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/attendance_record_model.dart';
import 'package:myapp/models/training_session_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:intl/intl.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Map<String, dynamic>> _children = [];
  List<TrainingSession> _trainingSessions = [];
  Map<String, AttendanceRecord> _attendanceMap = {};
  Map<String, AttendanceStatus> _pendingAttendance = {};
  String? _selectedChildId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener ID del usuario actual
      final parentId = _supabaseService.client.auth.currentUser?.id;
      
      if (parentId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no autenticado. Por favor, inicia sesión.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Cargar hijos del padre
      final children = await _supabaseService.getParentChildren(parentId);
      
      if (children.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes hijos registrados en ningún equipo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _children = children;
        _selectedChildId = children.first['child_id'] as String?;
      });

      // Cargar sesiones de entrenamiento
      await _loadTrainingSessions();
      
      // Cargar asistencia existente
      await _loadAttendanceRecords();
    } catch (e) {
      debugPrint("Error cargando datos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrainingSessions() async {
    if (_selectedChildId == null) return;

    try {
      // Cargar sesiones pasadas y futuras  
      final sessionsData = await _supabaseService.getParentTrainingSessions(_selectedChildId!);
      
      // Convertir a objetos TrainingSession (simplificado)
      final sessions = sessionsData.map<TrainingSession>((data) {
        return TrainingSession(
          id: data['id'] as String,
          teamId: (data['team_id'] as String?) ?? '',
          date: DateTime.parse(data['session_date'] as String),
          topic: data['notes'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      setState(() {
        _trainingSessions = sessions;
        // Inicializar estados pendientes
        _pendingAttendance = {
          for (var session in sessions)
            session.id: AttendanceStatus.present
        };
      });
    } catch (e) {
      debugPrint("Error cargando sesiones: $e");
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (_selectedChildId == null) return;

    try {
      final Map<String, AttendanceRecord> attendanceMap = {};
      
      for (var session in _trainingSessions) {
        final recordsData = await _supabaseService.getAttendanceRecords(session.id);
        
        // Buscar el registro del hijo actual
        final recordData = recordsData.firstWhere(
          (r) => r['player_id'] == _selectedChildId,
          orElse: () => <String, dynamic>{},
        );
        
        AttendanceRecord record;
        if (recordData.isNotEmpty) {
          final status = recordData['status'] as String;
          record = AttendanceRecord(
            id: recordData['id'] as String,
            sessionId: session.id,
            playerId: _selectedChildId!,
            status: status == 'present' 
                ? AttendanceStatus.present 
                : status == 'absent'
                    ? AttendanceStatus.absent
                    : AttendanceStatus.late,
            createdAt: DateTime.parse(recordData['created_at'] as String),
          );
        } else {
          record = AttendanceRecord(
            id: '',
            sessionId: session.id,
            playerId: _selectedChildId!,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
          );
        }
        
        attendanceMap[session.id] = record;
      }

      setState(() {
        _attendanceMap = attendanceMap;
        // Inicializar estados pendientes con valores existentes
        for (var entry in attendanceMap.entries) {
          _pendingAttendance[entry.key] = entry.value.status;
        }
      });
    } catch (e) {
      debugPrint("Error cargando registros de asistencia: $e");
    }
  }

  void _toggleAttendance(String sessionId) {
    if (_selectedChildId == null) return;

    setState(() {
      final currentStatus = _pendingAttendance[sessionId] ?? AttendanceStatus.present;
      // Ciclo: Presente -> Ausente -> Tarde -> Lesionado -> Enfermo -> Presente
      switch (currentStatus) {
        case AttendanceStatus.present:
          _pendingAttendance[sessionId] = AttendanceStatus.absent;
          break;
        case AttendanceStatus.absent:
          _pendingAttendance[sessionId] = AttendanceStatus.late;
          break;
        case AttendanceStatus.late:
          _pendingAttendance[sessionId] = AttendanceStatus.injured;
          break;
        case AttendanceStatus.injured:
          _pendingAttendance[sessionId] = AttendanceStatus.sick;
          break;
        case AttendanceStatus.sick:
          _pendingAttendance[sessionId] = AttendanceStatus.present;
          break;
      }
    });
  }

  Future<void> _saveAttendance(String sessionId) async {
    if (_selectedChildId == null) return;

    setState(() => _isSaving = true);

    try {
      final status = _pendingAttendance[sessionId] ?? AttendanceStatus.present;
      final statusString = status == AttendanceStatus.present 
          ? 'present' 
          : status == AttendanceStatus.absent
              ? 'absent'
              : 'late';
      
      final success = await _supabaseService.markChildAttendance(
        sessionId: sessionId,
        playerId: _selectedChildId!,
        status: statusString,
      );

      if (success) {
        // Recargar asistencia
        await _loadAttendanceRecords();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Asistencia guardada: ${_getStatusLabel(status)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la asistencia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error guardando asistencia: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.injured:
        return Colors.blue;
      case AttendanceStatus.sick:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.injured:
        return Icons.local_hospital;
      case AttendanceStatus.sick:
        return Icons.sick;
    }
  }

  String _getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Presente';
      case AttendanceStatus.absent:
        return 'Ausente';
      case AttendanceStatus.late:
        return 'Tarde';
      case AttendanceStatus.injured:
        return 'Lesionado';
      case AttendanceStatus.sick:
        return 'Enfermo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ASISTENCIA DE MI HIJO',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes hijos registrados',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Selector de hijo
                    _buildChildSelector(colorScheme),
                    const Divider(height: 1),
                    
                    // Lista de entrenamientos
                    Expanded(
                      child: _trainingSessions.isEmpty
                          ? Center(
                              child: Text(
                                'No hay entrenamientos programados',
                                style: GoogleFonts.roboto(
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _trainingSessions.length,
                              itemBuilder: (context, index) {
                                final session = _trainingSessions[index];
                                final status = _pendingAttendance[session.id] ??
                                    AttendanceStatus.present;
                                final isPast = session.date.isBefore(DateTime.now());
                                final hasRecord = _attendanceMap.containsKey(session.id);

                                return _buildSessionCard(
                                  session,
                                  status,
                                  isPast,
                                  hasRecord,
                                  colorScheme,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChildSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedChildId,
        decoration: InputDecoration(
          labelText: 'Seleccionar hijo',
          labelStyle: GoogleFonts.roboto(color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
        items: _children.map((child) {
          final childId = child['child_id'] as String;
          final childName = child['child_name'] as String? ?? 'Sin nombre';
          return DropdownMenuItem<String>(
            value: childId,
            child: Text(
              childName,
              style: GoogleFonts.roboto(),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          if (value != null) {
            setState(() => _selectedChildId = value);
            await _loadTrainingSessions();
            await _loadAttendanceRecords();
          }
        },
      ),
    );
  }

  Widget _buildSessionCard(
    TrainingSession session,
    AttendanceStatus status,
    bool isPast,
    bool hasRecord,
    ColorScheme colorScheme,
  ) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isToday = session.date.year == DateTime.now().year &&
        session.date.month == DateTime.now().month &&
        session.date.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: statusColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleAttendance(session.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Fecha y hora
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(session.date),
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HOY',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (session.topic != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 14,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                session.topic!,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Estado de asistencia
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Botón guardar
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveAttendance(session.id),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    hasRecord ? 'Actualizar Asistencia' : 'Guardar Asistencia',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
