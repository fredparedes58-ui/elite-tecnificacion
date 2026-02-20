import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/field_model.dart';
import 'package:myapp/models/booking_model.dart';
import 'package:myapp/services/field_service.dart';
import 'package:myapp/screens/booking_request_screen.dart';

class FieldScheduleScreen extends StatefulWidget {
  const FieldScheduleScreen({super.key});

  @override
  State<FieldScheduleScreen> createState() => _FieldScheduleScreenState();
}

class _FieldScheduleScreenState extends State<FieldScheduleScreen> {
  final FieldService _fieldService = FieldService();
  
  List<Field> _fields = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Configuración del horario (16:00 - 22:00 = 6 horas)
  final int _startHour = 16;
  final int _endHour = 22;
  final int _slotDuration = 30; // minutos por slot

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Cargar campos y reservas del día seleccionado
    final fields = await _fieldService.getAllFields();
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final bookings = await _fieldService.getBookingsByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    setState(() {
      _fields = fields;
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GESTIÓN DE CAMPOS',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateSelector(colorScheme),
                _buildLegend(colorScheme),
                Expanded(
                  child: _fields.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : _buildScheduleView(colorScheme),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingRequestScreen(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('SOLICITAR RESERVA'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildDateSelector(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.2),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE').format(_selectedDate).toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMMM yyyy').format(_selectedDate),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadData();
            },
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.today, color: colorScheme.primary),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
                _loadData();
              },
              tooltip: 'Hoy',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Entrenamiento', Colors.green, colorScheme),
          _buildLegendItem('Partido', Colors.red, colorScheme),
          _buildLegendItem('Táctica', Colors.purple, colorScheme),
          _buildLegendItem('Disponible', Colors.grey, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleView(ColorScheme colorScheme) {
    final totalHours = _endHour - _startHour;
    final totalSlots = (totalHours * 60) ~/ _slotDuration;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezados de campos
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'HORA',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ..._fields.map((field) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.2),
                              colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              field.name,
                              style: GoogleFonts.oswald(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              field.type,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            // Grid de horarios
            ...List.generate(totalSlots, (slotIndex) {
              final slotTime = _startHour * 60 + (slotIndex * _slotDuration);
              final hour = slotTime ~/ 60;
              final minute = slotTime % 60;
              final currentTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                hour,
                minute,
              );

              // Solo mostrar la hora cada hora (no cada 30 min)
              final showHourLabel = minute == 0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: showHourLabel
                        ? Center(
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          )
                        : null,
                  ),
                  ..._fields.map((field) {
                    final booking = _getBookingForSlot(field.id, currentTime);
                    return Expanded(
                      child: _buildTimeSlot(
                        colorScheme,
                        field,
                        currentTime,
                        booking,
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(
    ColorScheme colorScheme,
    Field field,
    DateTime slotTime,
    Booking? booking,
  ) {
    Color backgroundColor;
    Color borderColor;
    String? displayText;

    if (booking != null) {
      // Hay una reserva
      final purposeColor = _getPurposeColor(booking.purpose);
      backgroundColor = purposeColor.withValues(alpha: 0.2);
      borderColor = purposeColor.withValues(alpha: 0.5);
      displayText = booking.title;
    } else {
      // Disponible
      backgroundColor = Colors.grey.withValues(alpha: 0.05);
      borderColor = Colors.grey.withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTap: () {
        if (booking != null) {
          _showBookingDetails(booking);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: displayText != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    displayText,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Booking? _getBookingForSlot(String fieldId, DateTime slotTime) {
    final slotEnd = slotTime.add(Duration(minutes: _slotDuration));

    for (var booking in _bookings) {
      if (booking.fieldId == fieldId) {
        // Verificar si el slot está dentro del rango de la reserva
        if (slotTime.isBefore(booking.endTime) && slotEnd.isAfter(booking.startTime)) {
          return booking;
        }
      }
    }
    return null;
  }

  Color _getPurposeColor(String purpose) {
    switch (purpose) {
      case 'training':
        return Colors.green;
      case 'match':
        return Colors.red;
      case 'tactical':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPurposeColor(booking.purpose).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPurposeIcon(booking.purpose),
                        color: _getPurposeColor(booking.purpose),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.title,
                            style: GoogleFonts.oswald(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            Booking.getPurposeLabel(booking.purpose),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.location_on,
                  'Campo',
                  booking.fieldName ?? 'N/A',
                  colorScheme,
                ),
                _buildDetailRow(
                  Icons.access_time,
                  'Horario',
                  booking.timeRange,
                  colorScheme,
                ),
                _buildDetailRow(
                  Icons.timer,
                  'Duración',
                  '${booking.durationInMinutes} minutos',
                  colorScheme,
                ),
                if (booking.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Descripción:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.description!,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPurposeIcon(String purpose) {
    switch (purpose) {
      case 'training':
        return Icons.fitness_center;
      case 'match':
        return Icons.sports_soccer;
      case 'tactical':
        return Icons.grid_on;
      default:
        return Icons.event;
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stadium_outlined,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay campos registrados',
            style: GoogleFonts.oswald(
              fontSize: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura los campos en la base de datos',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
