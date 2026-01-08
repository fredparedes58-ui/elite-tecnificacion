import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
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
          players.add(Player.fromSupabaseProfile(
            profile,
            matchStatus: member['match_status'] as String?,
            statusNote: member['status_note'] as String?,
          ));
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

      await client.from('team_members').update({
        'match_status': matchStatus,
        'status_note': statusNote,
      }).match({
        'team_id': finalTeamId,
        'user_id': userId,
      });

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
          players.add(Player.fromSupabaseProfile(
            profile,
            matchStatus: member['match_status'] as String?,
            statusNote: member['status_note'] as String?,
          ));
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
          players.add(Player.fromSupabaseProfile(
            profile,
            matchStatus: member['match_status'] as String?,
            statusNote: member['status_note'] as String?,
          ));
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
      final p1 = await client
          .from('team_members')
          .select('match_status')
          .match({'team_id': finalTeamId, 'user_id': player1Id})
          .single();

      final p2 = await client
          .from('team_members')
          .select('match_status')
          .match({'team_id': finalTeamId, 'user_id': player2Id})
          .single();

      // Intercambiar estados
      await client.from('team_members').update({
        'match_status': p2['match_status'],
      }).match({'team_id': finalTeamId, 'user_id': player1Id});

      await client.from('team_members').update({
        'match_status': p1['match_status'],
      }).match({'team_id': finalTeamId, 'user_id': player2Id});

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
  Future<bool> saveAlignment(alignment_model.Alignment alignment, {String? teamId}) async {
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
  Future<List<alignment_model.Alignment>> getAlignments({String? teamId}) async {
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
            final positionsData = jsonDecode(data['player_positions'] as String) as Map<String, dynamic>;
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

          alignments.add(alignment_model.Alignment(
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
          ));
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
}
