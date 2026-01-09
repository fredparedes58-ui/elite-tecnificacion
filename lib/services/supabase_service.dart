import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/models/player_analysis_video_model.dart';
import 'package:myapp/models/training_session_model.dart';
import 'package:myapp/models/attendance_record_model.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/models/chat_channel_model.dart';
import 'package:myapp/models/chat_message_model.dart';
import 'dart:convert';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Error init Supabase: $e");
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  // ==========================================
  // GESTIÓN DE CONVOCATORIA Y PLANTILLA
  // ==========================================

  /// Obtiene todos los jugadores de un equipo con su estado de convocatoria
  Future<List<Player>> getTeamPlayers({String? teamId}) async {
    try {
      // Si no se proporciona teamId, obtenemos el primer equipo del usuario
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('team_members')
          .select('user_id, match_status, status_note, profiles(*)')
          .eq('team_id', finalTeamId);

      final List<Player> players = [];
      for (var member in response) {
        final profile = member['profiles'];
        if (profile != null) {
          players.add(
            Player.fromSupabaseProfile(
              profile,
              matchStatus: member['match_status'] as String?,
              statusNote: member['status_note'] as String?,
            ),
          );
        }
      }

      return players;
    } catch (e) {
      debugPrint("Error obteniendo jugadores: $e");
      return [];
    }
  }

  /// Actualiza el estado de convocatoria de un jugador
  Future<bool> updatePlayerMatchStatus({
    required String userId,
    required String matchStatus,
    String? statusNote,
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      await client
          .from('team_members')
          .update({'match_status': matchStatus, 'status_note': statusNote})
          .match({'team_id': finalTeamId, 'user_id': userId});

      return true;
    } catch (e) {
      debugPrint("Error actualizando estado del jugador: $e");
      return false;
    }
  }

  /// Obtiene solo los jugadores titulares
  Future<List<Player>> getStarterPlayers({String? teamId}) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('team_members')
          .select('user_id, match_status, status_note, profiles(*)')
          .eq('team_id', finalTeamId)
          .eq('match_status', 'starter');

      final List<Player> players = [];
      for (var member in response) {
        final profile = member['profiles'];
        if (profile != null) {
          players.add(
            Player.fromSupabaseProfile(
              profile,
              matchStatus: member['match_status'] as String?,
              statusNote: member['status_note'] as String?,
            ),
          );
        }
      }

      return players;
    } catch (e) {
      debugPrint("Error obteniendo titulares: $e");
      return [];
    }
  }

  /// Obtiene solo los jugadores suplentes
  Future<List<Player>> getSubstitutePlayers({String? teamId}) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('team_members')
          .select('user_id, match_status, status_note, profiles(*)')
          .eq('team_id', finalTeamId)
          .eq('match_status', 'sub');

      final List<Player> players = [];
      for (var member in response) {
        final profile = member['profiles'];
        if (profile != null) {
          players.add(
            Player.fromSupabaseProfile(
              profile,
              matchStatus: member['match_status'] as String?,
              statusNote: member['status_note'] as String?,
            ),
          );
        }
      }

      return players;
    } catch (e) {
      debugPrint("Error obteniendo suplentes: $e");
      return [];
    }
  }

  /// Obtiene el conteo de jugadores por estado
  Future<Map<String, int>> getPlayersCountByStatus({String? teamId}) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('team_members')
          .select('match_status')
          .eq('team_id', finalTeamId);

      int starters = 0;
      int substitutes = 0;
      int unselected = 0;

      for (var member in response) {
        final status = member['match_status'] as String?;
        switch (status) {
          case 'starter':
            starters++;
            break;
          case 'sub':
            substitutes++;
            break;
          case 'unselected':
            unselected++;
            break;
          default:
            substitutes++; // Por defecto contamos como suplente
        }
      }

      return {
        'starters': starters,
        'substitutes': substitutes,
        'unselected': unselected,
      };
    } catch (e) {
      debugPrint("Error obteniendo conteo de jugadores: $e");
      return {'starters': 0, 'substitutes': 0, 'unselected': 0};
    }
  }

  /// Intercambia el estado entre dos jugadores (útil para sustituciones)
  Future<bool> swapPlayerStatus({
    required String player1Id,
    required String player2Id,
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      // Obtener estados actuales
      final p1 = await client.from('team_members').select('match_status').match(
        {'team_id': finalTeamId, 'user_id': player1Id},
      ).single();

      final p2 = await client.from('team_members').select('match_status').match(
        {'team_id': finalTeamId, 'user_id': player2Id},
      ).single();

      // Intercambiar estados
      await client
          .from('team_members')
          .update({'match_status': p2['match_status']})
          .match({'team_id': finalTeamId, 'user_id': player1Id});

      await client
          .from('team_members')
          .update({'match_status': p1['match_status']})
          .match({'team_id': finalTeamId, 'user_id': player2Id});

      return true;
    } catch (e) {
      debugPrint("Error intercambiando jugadores: $e");
      return false;
    }
  }

  /// Obtiene el ID del equipo por defecto del usuario actual
  Future<String> _getDefaultTeamId() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final response = await client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .single();

      return response['team_id'] as String;
    } catch (e) {
      // Si no encuentra el equipo del usuario, intenta obtener el primer equipo disponible
      try {
        final team = await client.from('teams').select('id').limit(1).single();
        return team['id'] as String;
      } catch (e2) {
        debugPrint("Error obteniendo equipo por defecto: $e2");
        throw Exception("No se pudo obtener el equipo");
      }
    }
  }

  // ==========================================
  // GESTIÓN DE ALINEACIONES PERSONALIZADAS
  // ==========================================

  /// Guarda una alineación personalizada
  Future<bool> saveAlignment(
    alignment_model.Alignment alignment, {
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();
      final userId = client.auth.currentUser?.id;

      if (userId == null) throw Exception("Usuario no autenticado");

      // Convertir player positions a JSON
      final playerPositionsJson = alignment.playerPositions.map(
        (playerId, position) => MapEntry(playerId, {
          'x': position.offset.dx,
          'y': position.offset.dy,
          'role': position.role,
        }),
      );

      final data = {
        'id': alignment.id,
        'team_id': finalTeamId,
        'user_id': userId,
        'name': alignment.name,
        'formation': alignment.formation,
        'player_positions': jsonEncode(playerPositionsJson),
        'is_custom': alignment.isCustom,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Intentar actualizar primero, si no existe, insertar
      final existing = await client
          .from('alignments')
          .select('id')
          .eq('id', alignment.id)
          .maybeSingle();

      if (existing != null) {
        await client.from('alignments').update(data).eq('id', alignment.id);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        await client.from('alignments').insert(data);
      }

      return true;
    } catch (e) {
      debugPrint("Error guardando alineación: $e");
      return false;
    }
  }

  /// Obtiene todas las alineaciones del equipo
  Future<List<alignment_model.Alignment>> getAlignments({
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('alignments')
          .select()
          .eq('team_id', finalTeamId)
          .order('created_at', ascending: false);

      final List<alignment_model.Alignment> alignments = [];
      for (var data in response) {
        try {
          // Parsear player_positions JSON
          Map<String, alignment_model.PlayerPosition> positions = {};
          if (data['player_positions'] != null) {
            final positionsData =
                jsonDecode(data['player_positions'] as String)
                    as Map<String, dynamic>;
            positionsData.forEach((playerId, posData) {
              if (posData is Map<String, dynamic>) {
                positions[playerId] = alignment_model.PlayerPosition(
                  offset: Offset(
                    (posData['x'] as num).toDouble(),
                    (posData['y'] as num).toDouble(),
                  ),
                  role: posData['role'] as String?,
                );
              }
            });
          }

          alignments.add(
            alignment_model.Alignment(
              id: data['id'] as String,
              name: data['name'] as String,
              formation: data['formation'] as String? ?? '4-4-2',
              playerPositions: positions,
              createdAt: data['created_at'] != null
                  ? DateTime.parse(data['created_at'] as String)
                  : null,
              updatedAt: data['updated_at'] != null
                  ? DateTime.parse(data['updated_at'] as String)
                  : null,
              isCustom: data['is_custom'] as bool? ?? false,
            ),
          );
        } catch (e) {
          debugPrint("Error parseando alineación: $e");
        }
      }

      return alignments;
    } catch (e) {
      debugPrint("Error obteniendo alineaciones: $e");
      return [];
    }
  }

  /// Elimina una alineación personalizada
  Future<bool> deleteAlignment(String alignmentId) async {
    try {
      await client.from('alignments').delete().eq('id', alignmentId);
      return true;
    } catch (e) {
      debugPrint("Error eliminando alineación: $e");
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE VIDEOS DE ANÁLISIS DE JUGADORES
  // ==========================================

  /// Sube un video de análisis para un jugador
  Future<PlayerAnalysisVideo?> uploadPlayerAnalysisVideo({
    required String playerId,
    required String videoUrl,
    required String videoGuid,
    required String title,
    String? thumbnailUrl,
    String? comments,
    String? analysisType,
    int? durationSeconds,
    String? teamId,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final data = {
        'player_id': playerId,
        'coach_id': userId,
        'team_id': finalTeamId,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'video_guid': videoGuid,
        'title': title,
        'comments': comments,
        'analysis_type': analysisType,
        'duration_seconds': durationSeconds,
      };

      final response = await client
          .from('player_analysis_videos')
          .insert(data)
          .select()
          .single();

      return PlayerAnalysisVideo.fromJson(response);
    } catch (e) {
      debugPrint("Error subiendo video de análisis: $e");
      return null;
    }
  }

  /// Obtiene todos los videos de análisis de un jugador
  Future<List<PlayerAnalysisVideo>> getPlayerAnalysisVideos({
    required String playerId,
  }) async {
    try {
      final response = await client
          .from('player_analysis_videos_detailed')
          .select()
          .eq('player_id', playerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PlayerAnalysisVideo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error obteniendo videos de análisis: $e");
      return [];
    }
  }

  /// Obtiene un video de análisis por ID
  Future<PlayerAnalysisVideo?> getPlayerAnalysisVideoById(
    String videoId,
  ) async {
    try {
      final response = await client
          .from('player_analysis_videos_detailed')
          .select()
          .eq('id', videoId)
          .single();

      return PlayerAnalysisVideo.fromJson(response);
    } catch (e) {
      debugPrint("Error obteniendo video de análisis: $e");
      return null;
    }
  }

  /// Actualiza un video de análisis
  Future<bool> updatePlayerAnalysisVideo({
    required String videoId,
    String? title,
    String? comments,
    String? analysisType,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (comments != null) data['comments'] = comments;
      if (analysisType != null) data['analysis_type'] = analysisType;

      await client
          .from('player_analysis_videos')
          .update(data)
          .eq('id', videoId);

      return true;
    } catch (e) {
      debugPrint("Error actualizando video de análisis: $e");
      return false;
    }
  }

  /// Elimina un video de análisis
  Future<bool> deletePlayerAnalysisVideo(String videoId) async {
    try {
      await client.from('player_analysis_videos').delete().eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint("Error eliminando video de análisis: $e");
      return false;
    }
  }

  /// Obtiene todos los videos que el entrenador ha creado
  Future<List<PlayerAnalysisVideo>> getCoachAnalysisVideos() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final response = await client
          .from('player_analysis_videos_detailed')
          .select()
          .eq('coach_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PlayerAnalysisVideo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error obteniendo videos del entrenador: $e");
      return [];
    }
  }

  // ==========================================
  // GESTIÓN DE VIDEOS TÁCTICOS
  // ==========================================

  /// Sube un video táctico vinculado a una sesión o alineación
  Future<TacticalVideo?> uploadTacticalVideo({
    String? tacticalSessionId,
    String? alignmentId,
    required String videoUrl,
    required String videoGuid,
    required String title,
    String? thumbnailUrl,
    String? description,
    String videoType = 'reference',
    int? durationSeconds,
    String? teamId,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      if (tacticalSessionId == null && alignmentId == null) {
        throw Exception("Se requiere tactical_session_id o alignment_id");
      }

      final data = {
        'tactical_session_id': tacticalSessionId,
        'alignment_id': alignmentId,
        'team_id': finalTeamId,
        'coach_id': userId,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'video_guid': videoGuid,
        'title': title,
        'description': description,
        'video_type': videoType,
        'duration_seconds': durationSeconds,
      };

      final response = await client
          .from('tactical_videos')
          .insert(data)
          .select()
          .single();

      return TacticalVideo.fromJson(response);
    } catch (e) {
      debugPrint("Error subiendo video táctico: $e");
      return null;
    }
  }

  /// Obtiene videos tácticos de una sesión táctica
  Future<List<TacticalVideo>> getTacticalSessionVideos({
    required String tacticalSessionId,
  }) async {
    try {
      final response = await client
          .from('tactical_videos_detailed')
          .select()
          .eq('tactical_session_id', tacticalSessionId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TacticalVideo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error obteniendo videos tácticos: $e");
      return [];
    }
  }

  /// Obtiene videos tácticos de una alineación
  Future<List<TacticalVideo>> getAlignmentVideos({
    required String alignmentId,
  }) async {
    try {
      final response = await client
          .from('tactical_videos_detailed')
          .select()
          .eq('alignment_id', alignmentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TacticalVideo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error obteniendo videos de alineación: $e");
      return [];
    }
  }

  /// Elimina un video táctico
  Future<bool> deleteTacticalVideo(String videoId) async {
    try {
      await client.from('tactical_videos').delete().eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint("Error eliminando video táctico: $e");
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE ANÁLISIS PROMATCH (EVENTOS)
  // ==========================================

  /// Crea un evento de análisis (soporta modo Live y Video)
  Future<String?> createAnalysisEvent({
    required String matchId,
    required int matchTimestamp, // Tiempo real del partido
    required String eventType,
    int? videoTimestamp, // Nullable para modo Live
    String? teamId,
    String? playerId,
    String? videoGuid,
    String? eventTitle,
    String? voiceTranscript,
    double? voiceConfidence,
    String? drawingUrl,
    Map<String, dynamic>? drawingData,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final data = {
        'match_id': matchId,
        'team_id': finalTeamId,
        'coach_id': userId,
        'player_id': playerId,
        'video_guid': videoGuid,
        'match_timestamp': matchTimestamp,
        'video_timestamp': videoTimestamp,
        'event_type': eventType,
        'event_title': eventTitle,
        'voice_transcript': voiceTranscript,
        'voice_confidence': voiceConfidence,
        'drawing_url': drawingUrl,
        'drawing_data': drawingData,
        'notes': notes,
        'tags': tags,
      };

      final response = await client
          .from('analysis_events')
          .insert(data)
          .select('id')
          .single();

      debugPrint("✅ Evento de análisis creado: ${response['id']}");
      return response['id'] as String;
    } catch (e) {
      debugPrint("❌ Error creando evento de análisis: $e");
      return null;
    }
  }

  /// Obtiene todos los eventos de un partido
  Future<List<Map<String, dynamic>>> getMatchAnalysisEvents({
    required String matchId,
  }) async {
    try {
      final response = await client
          .from('analysis_events_detailed')
          .select()
          .eq('match_id', matchId)
          .order('video_timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo eventos de análisis: $e");
      return [];
    }
  }

  /// Actualiza un evento de análisis
  Future<bool> updateAnalysisEvent({
    required String eventId,
    String? eventTitle,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (eventTitle != null) data['event_title'] = eventTitle;
      if (notes != null) data['notes'] = notes;
      if (tags != null) data['tags'] = tags;

      await client.from('analysis_events').update(data).eq('id', eventId);

      return true;
    } catch (e) {
      debugPrint("❌ Error actualizando evento: $e");
      return false;
    }
  }

  /// Elimina un evento de análisis
  Future<bool> deleteAnalysisEvent(String eventId) async {
    try {
      await client.from('analysis_events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint("❌ Error eliminando evento: $e");
      return false;
    }
  }

  /// Obtiene tipos de eventos predefinidos
  Future<List<Map<String, dynamic>>> getEventTypes() async {
    try {
      final response = await client
          .from('event_types')
          .select()
          .order('category', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo tipos de eventos: $e");
      return [];
    }
  }

  /// Obtiene la línea de tiempo de análisis de un partido
  Future<List<Map<String, dynamic>>> getMatchAnalysisTimeline({
    required String matchId,
  }) async {
    try {
      final response = await client.rpc(
        'get_match_analysis_timeline',
        params: {'p_match_id': matchId},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo timeline: $e");
      return [];
    }
  }

  // ==========================================
  // SISTEMA HÍBRIDO (LIVE + SYNC)
  // ==========================================

  /// Verifica si un partido tiene eventos Live sin sincronizar
  Future<bool> hasUnsyncedLiveEvents(String matchId) async {
    try {
      final response = await client.rpc(
        'has_unsynced_live_events',
        params: {'p_match_id': matchId},
      );

      return response as bool? ?? false;
    } catch (e) {
      debugPrint("❌ Error verificando eventos sin sincronizar: $e");
      return false;
    }
  }

  /// Obtiene estadísticas de eventos Live de un partido
  Future<Map<String, dynamic>> getLiveEventsStats(String matchId) async {
    try {
      final response = await client.rpc(
        'get_live_events_stats',
        params: {'p_match_id': matchId},
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }

      return {
        'total_events': 0,
        'synced_events': 0,
        'unsynced_events': 0,
        'events_by_type': {},
      };
    } catch (e) {
      debugPrint("❌ Error obteniendo estadísticas de eventos: $e");
      return {
        'total_events': 0,
        'synced_events': 0,
        'unsynced_events': 0,
        'events_by_type': {},
      };
    }
  }

  /// Sincroniza eventos Live con el video
  Future<Map<String, dynamic>> syncLiveEventsWithVideo({
    required String matchId,
    required int videoOffset,
  }) async {
    try {
      final response = await client.rpc(
        'sync_live_events_with_video',
        params: {'p_match_id': matchId, 'p_video_offset': videoOffset},
      );

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map<String, dynamic>;
        debugPrint("✅ Sincronización completada: ${result['message']}");
        return result;
      }

      return {
        'events_synced': 0,
        'success': false,
        'message': 'No se pudo sincronizar',
      };
    } catch (e) {
      debugPrint("❌ Error sincronizando eventos: $e");
      return {'events_synced': 0, 'success': false, 'message': 'Error: $e'};
    }
  }

  /// Obtiene el offset de video de un partido
  Future<int?> getMatchVideoOffset(String matchId) async {
    try {
      final response = await client
          .from('matches')
          .select('video_offset')
          .eq('id', matchId)
          .maybeSingle();

      return response?['video_offset'] as int?;
    } catch (e) {
      debugPrint("❌ Error obteniendo video offset: $e");
      return null;
    }
  }

  /// Verifica si un partido ya está sincronizado
  Future<bool> isMatchSynced(String matchId) async {
    try {
      final response = await client
          .from('matches')
          .select('is_synced')
          .eq('id', matchId)
          .maybeSingle();

      return response?['is_synced'] as bool? ?? false;
    } catch (e) {
      debugPrint("❌ Error verificando sincronización: $e");
      return false;
    }
  }

  /// Actualiza información del video en el partido
  Future<bool> updateMatchVideo({
    required String matchId,
    String? videoUrl,
    String? videoGuid,
    int? videoDuration,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (videoUrl != null) data['video_url'] = videoUrl;
      if (videoGuid != null) data['video_guid'] = videoGuid;
      if (videoDuration != null) data['video_duration'] = videoDuration;
      data['updated_at'] = DateTime.now().toIso8601String();

      await client.from('matches').update(data).eq('id', matchId);

      return true;
    } catch (e) {
      debugPrint("❌ Error actualizando video del partido: $e");
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE ASISTENCIA A ENTRENAMIENTOS
  // ==========================================

  /// Crea una nueva sesión de entrenamiento
  Future<TrainingSession?> createTrainingSession({
    required DateTime date,
    String? topic,
    String? teamId,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final data = {
        'team_id': finalTeamId,
        'date': date.toIso8601String(),
        'topic': topic,
      };

      final response = await client
          .from('training_sessions')
          .insert(data)
          .select()
          .single();

      return TrainingSession.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error creando sesión de entrenamiento: $e");
      return null;
    }
  }

  /// Obtiene una sesión de entrenamiento por fecha
  Future<TrainingSession?> getTrainingSessionByDate({
    required DateTime date,
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      // Buscar sesión del día (sin importar la hora)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await client
          .from('training_sessions')
          .select()
          .eq('team_id', finalTeamId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .maybeSingle();

      if (response == null) return null;
      return TrainingSession.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo sesión de entrenamiento: $e");
      return null;
    }
  }

  /// Guarda o actualiza los registros de asistencia de múltiples jugadores
  /// Ahora permite que los padres marquen asistencia para sus hijos
  Future<bool> saveAttendanceRecords({
    required String sessionId,
    required Map<String, AttendanceStatus> playerAttendance,
    Map<String, String>? playerNotes,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      // Obtener información de la sesión
      final session = await client
          .from('training_sessions')
          .select('team_id')
          .eq('id', sessionId)
          .single();

      final teamId = session['team_id'] as String;

      // Verificar permisos: coach/admin o padre del jugador
      final memberCheck = await client
          .from('team_members')
          .select('role')
          .eq('team_id', teamId)
          .eq('user_id', userId)
          .maybeSingle();

      final isCoachOrAdmin =
          memberCheck != null &&
          ['coach', 'admin'].contains(memberCheck['role']);

      // Si no es coach/admin, verificar si es padre de alguno de los jugadores
      if (!isCoachOrAdmin) {
        bool hasPermission = false;
        for (var playerId in playerAttendance.keys) {
          final parentCheck = await client
              .from('parent_child_relationships')
              .select('id')
              .eq('parent_id', userId)
              .eq('child_id', playerId)
              .eq('team_id', teamId)
              .maybeSingle();

          if (parentCheck != null) {
            hasPermission = true;
            break;
          }
        }

        if (!hasPermission) {
          throw Exception("No tienes permisos para modificar asistencia");
        }
      }

      // Preparar datos para insertar/actualizar
      final List<Map<String, dynamic>> records = [];
      playerAttendance.forEach((playerId, status) {
        records.add({
          'session_id': sessionId,
          'player_id': playerId,
          'status': _attendanceStatusToString(status),
          'note': playerNotes?[playerId],
          'marked_by': userId, // Registrar quién marcó la asistencia
        });
      });

      // Usar upsert para insertar o actualizar
      await client
          .from('attendance_records')
          .upsert(records, onConflict: 'session_id,player_id');

      return true;
    } catch (e) {
      debugPrint("❌ Error guardando registros de asistencia: $e");
      return false;
    }
  }

  /// Obtiene los registros de asistencia de una sesión
  Future<List<AttendanceRecord>> getAttendanceRecords({
    required String sessionId,
  }) async {
    try {
      final response = await client
          .from('attendance_records')
          .select()
          .eq('session_id', sessionId);

      return (response as List)
          .map((json) => AttendanceRecord.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo registros de asistencia: $e");
      return [];
    }
  }

  /// Obtiene los registros de asistencia con información del marcador
  Future<Map<String, Map<String, dynamic>>> getAttendanceRecordsWithMarker({
    required String sessionId,
  }) async {
    try {
      final response = await client
          .from('attendance_records')
          .select(
            '*, marked_by_profile:profiles!marked_by(full_name, avatar_url)',
          )
          .eq('session_id', sessionId);

      final Map<String, Map<String, dynamic>> result = {};

      for (var record in response) {
        final playerId = record['player_id'] as String;
        final markedBy = record['marked_by'] as String?;

        // Obtener información del perfil del marcador
        Map<String, dynamic>? markedByProfile;
        if (record['marked_by_profile'] != null) {
          if (record['marked_by_profile'] is List &&
              (record['marked_by_profile'] as List).isNotEmpty) {
            markedByProfile =
                (record['marked_by_profile'] as List).first
                    as Map<String, dynamic>?;
          } else if (record['marked_by_profile'] is Map) {
            markedByProfile =
                record['marked_by_profile'] as Map<String, dynamic>?;
          }
        }

        // Crear el registro de asistencia
        final attendanceRecord = AttendanceRecord.fromJson(record);

        // Verificar si es padre o entrenador
        String? markerRole;
        if (markedBy != null) {
          try {
            final memberCheck = await client
                .from('team_members')
                .select('role')
                .eq('user_id', markedBy)
                .maybeSingle();

            if (memberCheck != null) {
              markerRole = memberCheck['role'] as String?;
            } else {
              // Verificar si es padre
              final parentCheck = await client
                  .from('parent_child_relationships')
                  .select('id')
                  .eq('parent_id', markedBy)
                  .limit(1)
                  .maybeSingle();

              if (parentCheck != null) {
                markerRole = 'parent';
              }
            }
          } catch (e) {
            debugPrint("Error verificando rol del marcador: $e");
          }
        }

        result[playerId] = {
          'record': attendanceRecord,
          'marked_by_id': markedBy,
          'marked_by_name':
              markedByProfile?['full_name'] as String? ?? 'Desconocido',
          'marked_by_avatar': markedByProfile?['avatar_url'] as String?,
          'marked_by_role': markerRole,
          'updated_at': record['updated_at'] as String?,
        };
      }

      return result;
    } catch (e) {
      debugPrint("❌ Error obteniendo registros con marcador: $e");
      // Fallback: obtener registros sin información del marcador
      try {
        final records = await getAttendanceRecords(sessionId: sessionId);
        final Map<String, Map<String, dynamic>> result = {};
        for (var record in records) {
          result[record.playerId] = {
            'record': record,
            'marked_by_id': record.markedBy,
            'marked_by_name': null,
            'marked_by_avatar': null,
            'marked_by_role': null,
            'updated_at': record.updatedAt?.toIso8601String(),
          };
        }
        return result;
      } catch (e2) {
        debugPrint("❌ Error en fallback: $e2");
        return {};
      }
    }
  }

  /// Obtiene el porcentaje de asistencia de un jugador
  Future<Map<String, dynamic>> getAttendanceRate({
    required String playerId,
    String? teamId,
    int daysBack = 30,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client.rpc(
        'get_attendance_rate',
        params: {
          'p_player_id': playerId,
          'p_team_id': finalTeamId,
          'p_days_back': daysBack,
        },
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }

      return {
        'total_sessions': 0,
        'present_count': 0,
        'absent_count': 0,
        'late_count': 0,
        'injured_count': 0,
        'sick_count': 0,
        'attendance_rate': 0.0,
      };
    } catch (e) {
      debugPrint("❌ Error obteniendo tasa de asistencia: $e");
      return {
        'total_sessions': 0,
        'present_count': 0,
        'absent_count': 0,
        'late_count': 0,
        'injured_count': 0,
        'sick_count': 0,
        'attendance_rate': 0.0,
      };
    }
  }

  /// Obtiene las últimas sesiones de entrenamiento
  Future<List<TrainingSession>> getRecentTrainingSessions({
    String? teamId,
    int limit = 10,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('training_sessions')
          .select()
          .eq('team_id', finalTeamId)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TrainingSession.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo sesiones recientes: $e");
      return [];
    }
  }

  /// Convierte AttendanceStatus a String
  String _attendanceStatusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.injured:
        return 'injured';
      case AttendanceStatus.sick:
        return 'sick';
    }
  }

  /// Obtiene los hijos de un padre
  Future<List<Map<String, dynamic>>> getParentChildren({String? teamId}) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client.rpc(
        'get_parent_children',
        params: {'p_parent_id': userId, 'p_team_id': finalTeamId},
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error obteniendo hijos del padre: $e");
      return [];
    }
  }

  /// Verifica si un padre puede marcar asistencia para un jugador
  Future<bool> canParentMarkAttendance({
    required String playerId,
    String? teamId,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('parent_child_relationships')
          .select('id')
          .eq('parent_id', userId)
          .eq('child_id', playerId)
          .eq('team_id', finalTeamId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint("❌ Error verificando permisos de padre: $e");
      return false;
    }
  }

  /// Obtiene las sesiones de entrenamiento para padres (solo equipos donde tienen hijos)
  Future<List<TrainingSession>> getParentTrainingSessions({
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      String finalTeamId = teamId ?? await _getDefaultTeamId();

      // Obtener equipos donde el padre tiene hijos
      final teamsResponse = await client
          .from('parent_child_relationships')
          .select('team_id')
          .eq('parent_id', userId)
          .eq('team_id', finalTeamId);

      if (teamsResponse.isEmpty) return [];

      // Obtener sesiones de entrenamiento para el equipo específico
      var query = client
          .from('training_sessions')
          .select()
          .eq('team_id', finalTeamId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query.order('date', ascending: false);

      return (response as List)
          .map((json) => TrainingSession.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint(
        "❌ Error obteniendo sesiones de entrenamiento para padres: $e",
      );
      return [];
    }
  }

  /// Marca asistencia para un solo jugador (método simplificado para padres)
  Future<bool> markChildAttendance({
    required String sessionId,
    required String playerId,
    required AttendanceStatus status,
    String? note,
  }) async {
    try {
      return await saveAttendanceRecords(
        sessionId: sessionId,
        playerAttendance: {playerId: status},
        playerNotes: note != null ? {playerId: note} : null,
      );
    } catch (e) {
      debugPrint("❌ Error marcando asistencia del hijo: $e");
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE TABLÓN DE ANUNCIOS OFICIALES
  // ==========================================

  /// Crea un nuevo comunicado en el tablón
  Future<NoticeBoardPost?> createNotice({
    String? teamId,
    required String title,
    required String content,
    String? attachmentUrl,
    NoticePriority priority = NoticePriority.normal,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final data = {
        'team_id': teamId,
        'author_id': userId,
        'title': title,
        'content': content,
        'attachment_url': attachmentUrl,
        'priority': priority == NoticePriority.urgent ? 'urgent' : 'normal',
      };

      final response = await client
          .from('notice_board_posts')
          .insert(data)
          .select()
          .single();

      return NoticeBoardPost.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error creando comunicado: $e");
      return null;
    }
  }

  /// Obtiene todos los comunicados visibles para el usuario actual
  Future<List<NoticeBoardPost>> getNotices({
    String? teamId,
    int limit = 50,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      // Si el usuario no está autenticado, retornar lista vacía sin lanzar excepción
      // para evitar bloquear el hot reload
      if (userId == null) {
        debugPrint(
          "⚠️ Usuario no autenticado, retornando lista vacía de comunicados",
        );
        return [];
      }

      // Obtener comunicados usando la vista con estadísticas
      final response = await client
          .from('notice_board_posts_with_stats')
          .select()
          .or('team_id.is.null,team_id.eq.$teamId')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => NoticeBoardPost.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo comunicados: $e");
      return [];
    }
  }

  /// Obtiene un comunicado por ID
  Future<NoticeBoardPost?> getNoticeById(String noticeId) async {
    try {
      final response = await client
          .from('notice_board_posts_with_stats')
          .select()
          .eq('id', noticeId)
          .maybeSingle();

      if (response == null) return null;
      return NoticeBoardPost.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo comunicado: $e");
      return null;
    }
  }

  /// Marca un comunicado como leído (crea acuse de recibo)
  Future<bool> markNoticeAsRead(String noticeId) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      // Usar upsert para evitar duplicados
      await client.from('notice_read_receipts').upsert({
        'notice_id': noticeId,
        'user_id': userId,
      }, onConflict: 'notice_id,user_id');

      return true;
    } catch (e) {
      debugPrint("❌ Error marcando comunicado como leído: $e");
      return false;
    }
  }

  /// Verifica si el usuario actual ha leído un comunicado
  Future<bool> hasReadNotice(String noticeId) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await client
          .from('notice_read_receipts')
          .select('id')
          .eq('notice_id', noticeId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint("❌ Error verificando lectura: $e");
      return false;
    }
  }

  /// Obtiene estadísticas de lectura de un comunicado
  Future<Map<String, dynamic>> getNoticeReadStats(String noticeId) async {
    try {
      final response = await client.rpc(
        'get_notice_read_stats',
        params: {'p_notice_id': noticeId},
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }

      return {
        'total_users': 0,
        'read_count': 0,
        'unread_count': 0,
        'read_percentage': 0.0,
      };
    } catch (e) {
      debugPrint("❌ Error obteniendo estadísticas de lectura: $e");
      return {
        'total_users': 0,
        'read_count': 0,
        'unread_count': 0,
        'read_percentage': 0.0,
      };
    }
  }

  /// Obtiene la lista de usuarios que NO han leído un comunicado
  Future<List<Map<String, dynamic>>> getUnreadUsers(String noticeId) async {
    try {
      final response = await client.rpc(
        'get_unread_users',
        params: {'p_notice_id': noticeId},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo usuarios sin leer: $e");
      return [];
    }
  }

  /// Actualiza un comunicado (solo el autor)
  Future<bool> updateNotice({
    required String noticeId,
    String? title,
    String? content,
    String? attachmentUrl,
    NoticePriority? priority,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (attachmentUrl != null) data['attachment_url'] = attachmentUrl;
      if (priority != null) {
        data['priority'] = priority == NoticePriority.urgent
            ? 'urgent'
            : 'normal';
      }

      await client
          .from('notice_board_posts')
          .update(data)
          .eq('id', noticeId)
          .eq('author_id', userId); // Solo el autor puede actualizar

      return true;
    } catch (e) {
      debugPrint("❌ Error actualizando comunicado: $e");
      return false;
    }
  }

  /// Elimina un comunicado (solo coaches/admins o el autor)
  Future<bool> deleteNotice(String noticeId) async {
    try {
      await client.from('notice_board_posts').delete().eq('id', noticeId);
      return true;
    } catch (e) {
      debugPrint("❌ Error eliminando comunicado: $e");
      return false;
    }
  }

  // ==========================================
  // SISTEMA DE CHAT INTELIGENTE
  // ==========================================

  /// Obtiene todos los canales de chat de un equipo
  Future<List<ChatChannel>> getTeamChatChannels({String? teamId}) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('chat_channels')
          .select()
          .eq('team_id', finalTeamId)
          .order('type', ascending: true);

      return (response as List)
          .map((json) => ChatChannel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo canales de chat: $e");
      return [];
    }
  }

  /// Asegura que existan los canales por defecto para un equipo
  Future<bool> ensureDefaultChannels({String? teamId}) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      await client.rpc(
        'ensure_default_channels',
        params: {'p_team_id': finalTeamId},
      );

      return true;
    } catch (e) {
      debugPrint("❌ Error creando canales por defecto: $e");
      return false;
    }
  }

  /// Obtiene un canal por tipo y equipo
  Future<ChatChannel?> getChannelByType({
    required ChatChannelType type,
    String? teamId,
  }) async {
    try {
      String finalTeamId = teamId ?? await _getDefaultTeamId();

      final response = await client
          .from('chat_channels')
          .select()
          .eq('team_id', finalTeamId)
          .eq('type', type.value)
          .maybeSingle();

      if (response == null) return null;
      return ChatChannel.fromJson(response);
    } catch (e) {
      debugPrint("❌ Error obteniendo canal por tipo: $e");
      return null;
    }
  }

  /// Obtiene los mensajes de un canal
  Future<List<ChatMessage>> getChannelMessages({
    required String channelId,
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('chat_messages_detailed')
          .select()
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      // Invertir para mostrar los más antiguos primero
      return messages.reversed.toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo mensajes del canal: $e");
      return [];
    }
  }

  /// Stream de mensajes en tiempo real para un canal
  Stream<List<ChatMessage>> streamChannelMessages(String channelId) {
    try {
      return client
          .from('chat_messages_detailed')
          .stream(primaryKey: ['id'])
          .eq('channel_id', channelId)
          .order('created_at', ascending: true)
          .map(
            (data) => (data as List)
                .map((json) => ChatMessage.fromJson(json))
                .toList(),
          );
    } catch (e) {
      debugPrint("❌ Error creando stream de mensajes: $e");
      return Stream.value([]);
    }
  }

  /// Envía un mensaje a un canal
  Future<ChatMessage?> sendMessage(CreateChatMessageDto message) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final data = {
        'channel_id': message.channelId,
        'user_id': userId,
        'content': message.content,
        if (message.mediaUrl != null) 'media_url': message.mediaUrl,
        if (message.mediaType != null) 'media_type': message.mediaType!.value,
      };

      final response = await client
          .from('chat_messages')
          .insert(data)
          .select()
          .single();

      // Obtener el mensaje completo con información del usuario
      final detailedResponse = await client
          .from('chat_messages_detailed')
          .select()
          .eq('id', response['id'] as String)
          .single();

      return ChatMessage.fromJson(detailedResponse);
    } catch (e) {
      debugPrint("❌ Error enviando mensaje: $e");
      return null;
    }
  }

  /// Actualiza un mensaje (solo el autor)
  Future<bool> updateMessage({
    required String messageId,
    String? content,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final data = <String, dynamic>{};
      if (content != null) data['content'] = content;

      await client
          .from('chat_messages')
          .update(data)
          .eq('id', messageId)
          .eq('user_id', userId); // Solo el autor puede actualizar

      return true;
    } catch (e) {
      debugPrint("❌ Error actualizando mensaje: $e");
      return false;
    }
  }

  /// Elimina un mensaje (autor o coach/admin)
  Future<bool> deleteMessage(String messageId) async {
    try {
      await client.from('chat_messages').delete().eq('id', messageId);
      return true;
    } catch (e) {
      debugPrint("❌ Error eliminando mensaje: $e");
      return false;
    }
  }

  /// Verifica si el usuario puede escribir en un canal
  Future<bool> canUserWriteInChannel({required String channelId}) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      // Obtener información del canal y del usuario
      final channelResponse = await client
          .from('chat_channels')
          .select('type, team_id')
          .eq('id', channelId)
          .single();

      final channelType = channelResponse['type'] as String;
      final teamId = channelResponse['team_id'] as String;

      // Si es canal general, todos pueden escribir
      if (channelType == 'general') return true;

      // Si es canal announcement, solo coaches/admins pueden escribir
      if (channelType == 'announcement') {
        final memberResponse = await client
            .from('team_members')
            .select('role')
            .eq('team_id', teamId)
            .eq('user_id', userId)
            .maybeSingle();

        if (memberResponse == null) return false;
        final role = memberResponse['role'] as String?;
        return ['coach', 'admin'].contains(role);
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error verificando permisos de escritura: $e");
      return false;
    }
  }

  // ==========================================
  // GESTIÓN DE MIEMBROS DEL EQUIPO
  // ==========================================

  /// Busca usuarios por email o nombre de usuario
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
  }) async {
    try {
      // Buscar por nombre completo en profiles
      final nameResults = await client
          .from('profiles')
          .select('id, full_name')
          .ilike('full_name', '%$query%')
          .limit(20);

      // Obtener emails desde auth.users usando RPC o función personalizada
      // Por ahora, retornamos los usuarios encontrados sin email
      // El email se puede obtener después si es necesario
      final List<Map<String, dynamic>> users = [];

      for (var profile in nameResults) {
        final userId = profile['id'] as String;

        // Intentar obtener el email desde auth.users usando admin API
        // Nota: Esto requiere permisos especiales, por ahora retornamos sin email
        users.add({
          'id': userId,
          'full_name': profile['full_name'] ?? 'Usuario',
          'email': null, // Se puede obtener después si es necesario
        });
      }

      return users;
    } catch (e) {
      debugPrint("❌ Error buscando usuarios: $e");
      return [];
    }
  }

  /// Obtiene todos los equipos disponibles
  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      final response = await client
          .from('teams')
          .select('id, name, category')
          .order('name');

      return (response as List)
          .map(
            (team) => {
              'id': team['id'],
              'name': team['name'],
              'category': team['category'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint("❌ Error obteniendo equipos: $e");
      return [];
    }
  }

  /// Agrega un usuario a un equipo
  Future<bool> addUserToTeam({
    required String userId,
    required String teamId,
    String role = 'player',
    String? userFullName,
  }) async {
    try {
      // Verificar que el usuario actual tiene permisos (coach o admin)
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final memberCheck = await client
          .from('team_members')
          .select('role')
          .eq('team_id', teamId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (memberCheck == null ||
          !['coach', 'admin'].contains(memberCheck['role'])) {
        throw Exception("No tienes permisos para agregar miembros");
      }

      // Verificar si el usuario ya está en el equipo
      final existingMember = await client
          .from('team_members')
          .select('id')
          .eq('team_id', teamId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception("El usuario ya está en este equipo");
      }

      // Obtener el nombre completo del usuario si no se proporciona
      String finalFullName = userFullName ?? '';
      if (finalFullName.isEmpty) {
        final profile = await client
            .from('profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();
        finalFullName = profile?['full_name'] as String? ?? 'Usuario';
      }

      // Preparar datos para insertar
      final insertData = <String, dynamic>{
        'user_id': userId,
        'team_id': teamId,
        'role': role,
        'match_status': 'sub',
      };

      // Agregar user_full_name solo si el campo existe en la tabla
      // (algunas instalaciones pueden no tenerlo)
      try {
        insertData['user_full_name'] = finalFullName;
      } catch (e) {
        // Si el campo no existe, continuar sin él
        debugPrint("⚠️ Campo user_full_name no disponible: $e");
      }

      // Agregar el usuario al equipo
      await client.from('team_members').insert(insertData);

      return true;
    } catch (e) {
      debugPrint("❌ Error agregando usuario al equipo: $e");
      rethrow;
    }
  }
}
