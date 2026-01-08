import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/models/field_model.dart';
import 'package:myapp/models/booking_model.dart';
import 'package:myapp/models/booking_request_model.dart';

class FieldService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // GESTIÓN DE CAMPOS
  // ==========================================

  /// Obtiene todos los campos activos
  Future<List<Field>> getAllFields() async {
    try {
      final response = await _client
          .from('fields')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Field.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo campos: $e');
      return [];
    }
  }

  /// Obtiene un campo específico por ID
  Future<Field?> getFieldById(String fieldId) async {
    try {
      final response = await _client
          .from('fields')
          .select()
          .eq('id', fieldId)
          .single();

      return Field.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error obteniendo campo: $e');
      return null;
    }
  }

  /// Obtiene campos disponibles en un rango de tiempo específico
  Future<List<Field>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Llamar a la función RPC de Supabase
      final response = await _client.rpc('get_available_fields', params: {
        'p_start_time': startTime.toIso8601String(),
        'p_end_time': endTime.toIso8601String(),
      });

      return (response as List).map((json) {
        return Field(
          id: json['field_id'] as String,
          name: json['field_name'] as String,
          type: json['field_type'] as String,
          location: json['field_location'] as String?,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo campos disponibles: $e');
      return [];
    }
  }

  // ==========================================
  // GESTIÓN DE RESERVAS (BOOKINGS)
  // ==========================================

  /// Obtiene todas las reservas (con opción de filtrar por fecha)
  Future<List<Booking>> getAllBookings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('bookings')
          .select('*, fields(name), teams(name)')
          .order('start_time');

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      final response = await query;

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas: $e');
      return [];
    }
  }

  /// Obtiene reservas de un campo específico
  Future<List<Booking>> getBookingsByField(String fieldId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, fields(name), teams(name)')
          .eq('field_id', fieldId)
          .order('start_time');

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas del campo: $e');
      return [];
    }
  }

  /// Obtiene reservas de un rango de fechas (para la vista de calendario)
  Future<List<Booking>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, fields(name), teams(name)')
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time');

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas por fecha: $e');
      return [];
    }
  }

  /// 🔥 CRÍTICO: Verifica si existe un conflicto de horario
  Future<Map<String, dynamic>> checkBookingConflict({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    try {
      final response = await _client.rpc('check_booking_conflict', params: {
        'p_field_id': fieldId,
        'p_start_time': startTime.toIso8601String(),
        'p_end_time': endTime.toIso8601String(),
        'p_exclude_booking_id': excludeBookingId,
      });

      // La función devuelve una fila con la info del conflicto
      if (response is List && response.isNotEmpty) {
        final conflict = response[0];
        return {
          'hasConflict': conflict['conflict_exists'] ?? false,
          'conflictingBookingId': conflict['conflicting_booking_id'],
          'conflictingTeamId': conflict['conflicting_team_id'],
          'conflictingTitle': conflict['conflicting_title'],
          'conflictingStart': conflict['conflicting_start'] != null
              ? DateTime.parse(conflict['conflicting_start'])
              : null,
          'conflictingEnd': conflict['conflicting_end'] != null
              ? DateTime.parse(conflict['conflicting_end'])
              : null,
        };
      }

      return {'hasConflict': false};
    } catch (e) {
      debugPrint('❌ Error verificando conflictos: $e');
      return {'hasConflict': false, 'error': e.toString()};
    }
  }

  /// Crea una nueva reserva (con validación automática en la BD)
  Future<Map<String, dynamic>> createBooking({
    required String fieldId,
    required String teamId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
    required String title,
    String? description,
  }) async {
    try {
      // Validar manualmente ANTES de insertar (para dar feedback amigable)
      final conflictCheck = await checkBookingConflict(
        fieldId: fieldId,
        startTime: startTime,
        endTime: endTime,
      );

      if (conflictCheck['hasConflict'] == true) {
        return {
          'success': false,
          'error': 'CONFLICTO DE HORARIO',
          'message':
              'Ya existe una reserva "${conflictCheck['conflictingTitle']}" en ese horario.',
          'conflictDetails': conflictCheck,
        };
      }

      // Si no hay conflictos, insertar
      final userId = _client.auth.currentUser?.id;

      final response = await _client.from('bookings').insert({
        'field_id': fieldId,
        'team_id': teamId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'purpose': purpose,
        'title': title,
        'description': description,
        'created_by': userId,
      }).select('*, fields(name)').single();

      return {
        'success': true,
        'booking': Booking.fromJson(response),
        'message': '✅ Reserva creada exitosamente',
      };
    } catch (e) {
      debugPrint('❌ Error creando reserva: $e');
      return {
        'success': false,
        'error': 'Error al crear reserva',
        'message': e.toString(),
      };
    }
  }

  /// Actualiza una reserva existente
  Future<Map<String, dynamic>> updateBooking({
    required String bookingId,
    String? fieldId,
    DateTime? startTime,
    DateTime? endTime,
    String? title,
    String? description,
  }) async {
    try {
      // Si se cambia el campo o el horario, validar conflictos
      if (fieldId != null || startTime != null || endTime != null) {
        // Obtener la reserva actual
        final current = await _client
            .from('bookings')
            .select()
            .eq('id', bookingId)
            .single();

        final finalFieldId = fieldId ?? current['field_id'];
        final finalStartTime = startTime ?? DateTime.parse(current['start_time']);
        final finalEndTime = endTime ?? DateTime.parse(current['end_time']);

        final conflictCheck = await checkBookingConflict(
          fieldId: finalFieldId,
          startTime: finalStartTime,
          endTime: finalEndTime,
          excludeBookingId: bookingId,
        );

        if (conflictCheck['hasConflict'] == true) {
          return {
            'success': false,
            'error': 'CONFLICTO DE HORARIO',
            'message': 'El cambio genera un conflicto con otra reserva.',
            'conflictDetails': conflictCheck,
          };
        }
      }

      // Preparar datos a actualizar
      final updateData = <String, dynamic>{};
      if (fieldId != null) updateData['field_id'] = fieldId;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      final response = await _client
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select('*, fields(name)')
          .single();

      return {
        'success': true,
        'booking': Booking.fromJson(response),
        'message': '✅ Reserva actualizada exitosamente',
      };
    } catch (e) {
      debugPrint('❌ Error actualizando reserva: $e');
      return {
        'success': false,
        'error': 'Error al actualizar reserva',
        'message': e.toString(),
      };
    }
  }

  /// Elimina una reserva
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _client.from('bookings').delete().eq('id', bookingId);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando reserva: $e');
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE SOLICITUDES (BOOKING REQUESTS)
  // ==========================================

  /// Crea una solicitud de reserva
  Future<Map<String, dynamic>> createBookingRequest({
    required String desiredFieldId,
    required DateTime desiredStartTime,
    required DateTime desiredEndTime,
    required String purpose,
    required String title,
    String? reason,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final userName = _client.auth.currentUser?.email ?? 'Entrenador';

      // Verificar disponibilidad antes de crear la solicitud
      final conflictCheck = await checkBookingConflict(
        fieldId: desiredFieldId,
        startTime: desiredStartTime,
        endTime: desiredEndTime,
      );

      if (conflictCheck['hasConflict'] == true) {
        return {
          'success': false,
          'error': 'CONFLICTO DE HORARIO',
          'message':
              'El horario solicitado ya está ocupado por "${conflictCheck['conflictingTitle']}".',
          'conflictDetails': conflictCheck,
        };
      }

      final response = await _client.from('booking_requests').insert({
        'requester_id': userId,
        'requester_name': userName,
        'desired_field_id': desiredFieldId,
        'desired_start_time': desiredStartTime.toIso8601String(),
        'desired_end_time': desiredEndTime.toIso8601String(),
        'purpose': purpose,
        'title': title,
        'reason': reason,
      }).select('*, fields(name)').single();

      return {
        'success': true,
        'request': BookingRequest.fromJson(response),
        'message': '✅ Solicitud enviada. Pendiente de aprobación.',
      };
    } catch (e) {
      debugPrint('❌ Error creando solicitud: $e');
      return {
        'success': false,
        'error': 'Error al crear solicitud',
        'message': e.toString(),
      };
    }
  }

  /// Obtiene todas las solicitudes pendientes
  Future<List<BookingRequest>> getPendingRequests() async {
    try {
      final response = await _client
          .from('booking_requests')
          .select('*, fields(name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo solicitudes pendientes: $e');
      return [];
    }
  }

  /// Obtiene todas las solicitudes de un usuario
  Future<List<BookingRequest>> getRequestsByUser(String userId) async {
    try {
      final response = await _client
          .from('booking_requests')
          .select('*, fields(name)')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo solicitudes del usuario: $e');
      return [];
    }
  }

  /// Aprueba una solicitud (y crea automáticamente la reserva)
  Future<Map<String, dynamic>> approveRequest({
    required String requestId,
    String? reviewNotes,
  }) async {
    try {
      // Obtener la solicitud
      final request = await _client
          .from('booking_requests')
          .select()
          .eq('id', requestId)
          .single();

      // Crear la reserva automáticamente
      final bookingResult = await createBooking(
        fieldId: request['desired_field_id'],
        teamId: 'TEAM_ID_TEMPORAL', // Aquí deberías obtener el team_id del usuario
        startTime: DateTime.parse(request['desired_start_time']),
        endTime: DateTime.parse(request['desired_end_time']),
        purpose: request['purpose'],
        title: request['title'],
        description: request['reason'],
      );

      if (!bookingResult['success']) {
        return {
          'success': false,
          'error': 'No se pudo crear la reserva',
          'message': bookingResult['message'],
        };
      }

      // Actualizar la solicitud a "approved"
      final userId = _client.auth.currentUser?.id;
      await _client.from('booking_requests').update({
        'status': 'approved',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'review_notes': reviewNotes,
      }).eq('id', requestId);

      return {
        'success': true,
        'message': '✅ Solicitud aprobada y reserva creada',
        'booking': bookingResult['booking'],
      };
    } catch (e) {
      debugPrint('❌ Error aprobando solicitud: $e');
      return {
        'success': false,
        'error': 'Error al aprobar solicitud',
        'message': e.toString(),
      };
    }
  }

  /// Rechaza una solicitud
  Future<bool> rejectRequest({
    required String requestId,
    String? reviewNotes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('booking_requests').update({
        'status': 'rejected',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'review_notes': reviewNotes,
      }).eq('id', requestId);

      return true;
    } catch (e) {
      debugPrint('❌ Error rechazando solicitud: $e');
      return false;
    }
  }
}
