// ============================================================
// Calendario Escolar - Solo lectura para padres
// Eventos, cierres, entrenamientos especiales
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolCalendarScreen extends StatefulWidget {
  const SchoolCalendarScreen({super.key});

  @override
  State<SchoolCalendarScreen> createState() => _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends State<SchoolCalendarScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final endOfYear = DateTime(now.year + 1, 1, 1).toUtc().toIso8601String();

      final res = await Supabase.instance.client
          .from('school_calendar_events')
          .select('id, title, description, event_type, start_at, end_at')
          .gte('start_at', now.toIso8601String())
          .lte('start_at', endOfYear)
          .order('start_at', ascending: true);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('SchoolCalendarScreen error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'closure':
        return Icons.event_busy;
      case 'special_training':
        return Icons.fitness_center;
      default:
        return Icons.event;
    }
  }

  String _labelForType(String? type) {
    switch (type) {
      case 'closure':
        return 'Cierre';
      case 'special_training':
        return 'Entrenamiento especial';
      default:
        return 'Evento';
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'closure':
        return Colors.red;
      case 'special_training':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendario Escolar',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo cargar el calendario',
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadEvents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay eventos programados',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final e = _events[index];
                          final start = e['start_at'] != null
                              ? DateTime.parse(e['start_at'] as String)
                              : null;
                          final type = e['event_type'] as String?;
                          final color = _colorForType(type);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.2),
                                child: Icon(_iconForType(type), color: color, size: 22),
                              ),
                              title: Text(
                                e['title'] as String? ?? 'Sin título',
                                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (start != null)
                                    Text(
                                      DateFormat('EEEE d MMM y • HH:mm', 'es').format(start.toLocal()),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (e['description'] != null && (e['description'] as String).isNotEmpty)
                                    Text(
                                      e['description'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  Text(
                                    _labelForType(type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
