// ============================================================
// PANTALLA: CONTROL DE ASISTENCIA A ENTRENAMIENTOS
// ============================================================
// Herramienta rápida para pasar lista en 10 segundos
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/training_session_model.dart';
import 'package:myapp/models/attendance_record_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  DateTime _selectedDate = DateTime.now();
  TrainingSession? _currentSession;
  List<Player> _players = [];
  Map<String, AttendanceStatus> _attendanceMap = {};
  final Map<String, String> _notesMap = {};
  Map<String, Map<String, dynamic>> _markerInfo = {}; // Información de quién marcó la asistencia
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
      // Cargar jugadores del equipo
      final players = await _supabaseService.getTeamPlayers();
      setState(() {
        _players = players;
        // Inicializar todos como "presente" por defecto
        _attendanceMap = {
          for (var player in players)
            player.id ?? '': AttendanceStatus.present
        };
      });

      // Buscar sesión del día seleccionado
      final session = await _supabaseService.getTrainingSessionByDate(
        date: _selectedDate,
      );

      if (session != null) {
        // Cargar registros existentes con información del marcador
        final markerInfo = await _supabaseService.getAttendanceRecordsWithMarker(
          sessionId: session.id,
        );

        setState(() {
          _currentSession = session;
          _markerInfo = markerInfo;
          
          for (var entry in markerInfo.entries) {
            final playerId = entry.key;
            final info = entry.value;
            final record = info['record'] as AttendanceRecord;
            
            _attendanceMap[playerId] = record.status;
            if (record.note != null && record.note!.isNotEmpty) {
              _notesMap[playerId] = record.note!;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSession() async {
    final topic = await _showTopicDialog();
    if (topic == null) return;

    final session = await _supabaseService.createTrainingSession(
      date: _selectedDate,
      topic: topic,
    );

    if (session != null) {
      setState(() => _currentSession = session);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión creada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la sesión')),
      );
    }
  }

  Future<String?> _showTopicDialog() async {
    final topics = ['Físico', 'Táctica', 'Técnica', 'Partido', 'Otro'];
    String? selectedTopic;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de Entrenamiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: topics.map((topic) {
            return RadioListTile<String>(
              title: Text(topic),
              value: topic,
              groupValue: selectedTopic,
              onChanged: (value) {
                setState(() => selectedTopic = value);
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleAttendance(String playerId) {
    if (!_attendanceMap.containsKey(playerId)) return;

    setState(() {
      final currentStatus = _attendanceMap[playerId]!;
      // Ciclo: Presente -> Ausente -> Tarde -> Lesionado -> Enfermo -> Presente
      switch (currentStatus) {
        case AttendanceStatus.present:
          _attendanceMap[playerId] = AttendanceStatus.absent;
          break;
        case AttendanceStatus.absent:
          _attendanceMap[playerId] = AttendanceStatus.late;
          break;
        case AttendanceStatus.late:
          _attendanceMap[playerId] = AttendanceStatus.injured;
          break;
        case AttendanceStatus.injured:
          _attendanceMap[playerId] = AttendanceStatus.sick;
          break;
        case AttendanceStatus.sick:
          _attendanceMap[playerId] = AttendanceStatus.present;
          break;
      }
    });
  }

  Future<void> _showNoteDialog(String playerId, String playerName) async {
    final controller = TextEditingController(
      text: _notesMap[playerId] ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota para $playerName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej: Llegó 10 min tarde por tráfico',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result.isEmpty) {
          _notesMap.remove(playerId);
        } else {
          _notesMap[playerId] = result;
        }
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes crear una sesión para hoy'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _supabaseService.saveAttendanceRecords(
      sessionId: _currentSession!.id,
      playerAttendance: _attendanceMap,
      playerNotes: _notesMap.isNotEmpty ? _notesMap : null,
    );

    setState(() => _isSaving = false);

    if (success) {
      // Recargar datos para obtener información actualizada del marcador
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la asistencia'),
          backgroundColor: Colors.red,
        ),
      );
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Ahora';
          }
          return 'Hace ${difference.inMinutes}m';
        }
        return 'Hace ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays}d';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  Color _getMarkerColor(String? role) {
    switch (role) {
      case 'parent':
        return Colors.purple;
      case 'coach':
      case 'admin':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getMarkerIcon(String? role) {
    switch (role) {
      case 'parent':
        return Icons.family_restroom;
      case 'coach':
      case 'admin':
        return Icons.sports_soccer;
      default:
        return Icons.person_outline;
    }
  }

  String _getMarkerLabel(String? role) {
    switch (role) {
      case 'parent':
        return 'Padre/Madre';
      case 'coach':
        return 'Entrenador';
      case 'admin':
        return 'Admin';
      default:
        return 'Marcado por';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CONTROL DE ASISTENCIA',
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
          : Column(
              children: [
                // Selector de fecha y botón crear sesión
                _buildHeader(colorScheme),
                const Divider(height: 1),
                
                // Lista de jugadores
                Expanded(
                  child: _players.isEmpty
                      ? Center(
                          child: Text(
                            'No hay jugadores en el equipo',
                            style: GoogleFonts.roboto(
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            final player = _players[index];
                            final playerId = player.id ?? '';
                            final status = _attendanceMap[playerId] ??
                                AttendanceStatus.present;
                            final hasNote = _notesMap.containsKey(playerId);
                            final markerInfo = _markerInfo[playerId];

                            return _buildPlayerCard(
                              player,
                              status,
                              hasNote,
                              markerInfo,
                              colorScheme,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _currentSession != null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveAttendance,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Asistencia'),
              backgroundColor: colorScheme.primary,
            )
          : null,
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_currentSession == null)
                ElevatedButton.icon(
                  onPressed: _createSession,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
            ],
          ),
          if (_currentSession != null && _currentSession!.topic != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tema: ${_currentSession!.topic}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    Player player,
    AttendanceStatus status,
    bool hasNote,
    Map<String, dynamic>? markerInfo,
    ColorScheme colorScheme,
  ) {
    final playerId = player.id ?? '';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleAttendance(playerId),
        onLongPress: () => _showNoteDialog(playerId, player.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage(player.image),
                backgroundColor: colorScheme.surface,
              ),
              const SizedBox(width: 16),
              
              // Nombre y número
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (player.number != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '#${player.number}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                    if (hasNote) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _notesMap[playerId] ?? '',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: Colors.amber,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Información de quién marcó la asistencia
                    if (markerInfo != null && markerInfo['marked_by_name'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getMarkerColor(markerInfo['marked_by_role']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getMarkerColor(markerInfo['marked_by_role']).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getMarkerIcon(markerInfo['marked_by_role']),
                              size: 12,
                              color: _getMarkerColor(markerInfo['marked_by_role']),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${_getMarkerLabel(markerInfo['marked_by_role'])}: ${markerInfo['marked_by_name']}',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: _getMarkerColor(markerInfo['marked_by_role']),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (markerInfo['updated_at'] != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${_formatDate(markerInfo['updated_at'])}',
                                style: GoogleFonts.roboto(
                                  fontSize: 9,
                                  color: _getMarkerColor(markerInfo['marked_by_role']).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
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
        ),
      ),
    );
  }
}
