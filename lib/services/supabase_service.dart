import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/models/player_model.dart';

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
}
