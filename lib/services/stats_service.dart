// ============================================================
// SERVICIO: MATCH STATS & TOP SCORERS
// ============================================================
// Maneja todas las operaciones de estadísticas de partidos y rankings
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_stats_model.dart';

class StatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CRUD BÁSICO: MATCH STATS
  // ============================================================

  /// Obtener estadísticas de un partido específico
  Future<List<MatchStats>> getMatchStats(String matchId) async {
    try {
      final response = await _supabase
          .from('match_stats')
          .select()
          .eq('match_id', matchId)
          .order('goals', ascending: false);

      return (response as List)
          .map((json) => MatchStats.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting match stats: $e');
      return [];
    }
  }

  /// Guardar o actualizar estadísticas de múltiples jugadores
  Future<bool> saveMatchStats({
    required String matchId,
    required String teamId,
    required List<Map<String, dynamic>> playersStats,
  }) async {
    try {
      // Preparar los datos para upsert
      final List<Map<String, dynamic>> statsToSave = playersStats.map((stat) {
        return {
          'match_id': matchId,
          'player_id': stat['player_id'],
          'team_id': teamId,
          'goals': stat['goals'] ?? 0,
          'assists': stat['assists'] ?? 0,
          'minutes_played': stat['minutes_played'] ?? 0,
          'yellow_cards': stat['yellow_cards'] ?? 0,
          'red_cards': stat['red_cards'] ?? 0,
        };
      }).toList();

      // Usar upsert para insertar o actualizar (basado en match_id + player_id)
      await _supabase.from('match_stats').upsert(
            statsToSave,
            onConflict: 'match_id,player_id',
          );

      return true;
    } catch (e) {
      debugPrint('Error saving match stats: $e');
      return false;
    }
  }

  /// Actualizar estadísticas de un jugador específico
  Future<bool> updatePlayerMatchStats({
    required String matchId,
    required String playerId,
    required String teamId,
    required int goals,
    required int assists,
    required int minutesPlayed,
  }) async {
    try {
      await _supabase.from('match_stats').upsert({
        'match_id': matchId,
        'player_id': playerId,
        'team_id': teamId,
        'goals': goals,
        'assists': assists,
        'minutes_played': minutesPlayed,
      }, onConflict: 'match_id,player_id');

      return true;
    } catch (e) {
      debugPrint('Error updating player stats: $e');
      return false;
    }
  }

  /// Eliminar estadísticas de un partido
  Future<bool> deleteMatchStats(String matchId) async {
    try {
      await _supabase.from('match_stats').delete().eq('match_id', matchId);
      return true;
    } catch (e) {
      debugPrint('Error deleting match stats: $e');
      return false;
    }
  }

  // ============================================================
  // RANKINGS: TOP SCORERS
  // ============================================================

  /// TAB 1: Goleadores del equipo específico
  Future<List<TopScorer>> getTeamTopScorers({
    required String teamId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_team_top_scorers',
        params: {
          'p_team_id': teamId,
          'p_limit': limit,
        },
      );

      return (response as List)
          .map((json) => TopScorer.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting team top scorers: $e');
      return [];
    }
  }

  /// TAB 2: Goleadores por categoría (ej: todos los Alevines)
  Future<List<TopScorer>> getCategoryTopScorers({
    required String category,
    required String clubId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_category_top_scorers',
        params: {
          'p_category': category,
          'p_club_id': clubId,
          'p_limit': limit,
        },
      );

      return (response as List)
          .map((json) => TopScorer.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting category top scorers: $e');
      return [];
    }
  }

  /// TAB 3: Goleadores globales del club (todas las categorías)
  Future<List<TopScorer>> getClubTopScorers({
    required String clubId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_club_top_scorers',
        params: {
          'p_club_id': clubId,
          'p_limit': limit,
        },
      );

      return (response as List)
          .map((json) => TopScorer.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting club top scorers: $e');
      return [];
    }
  }

  // ============================================================
  // CONSULTAS AVANZADAS
  // ============================================================

  /// Obtener estadísticas acumuladas de un jugador
  Future<Map<String, dynamic>?> getPlayerTotalStats(String playerId) async {
    try {
      final response = await _supabase
          .from('match_stats')
          .select('goals, assists, minutes_played')
          .eq('player_id', playerId);

      if (response.isEmpty) return null;

      // Calcular totales
      int totalGoals = 0;
      int totalAssists = 0;
      int totalMinutes = 0;

      for (var stat in response) {
        totalGoals += (stat['goals'] as int?) ?? 0;
        totalAssists += (stat['assists'] as int?) ?? 0;
        totalMinutes += (stat['minutes_played'] as int?) ?? 0;
      }

      return {
        'total_goals': totalGoals,
        'total_assists': totalAssists,
        'matches_played': response.length,
        'total_minutes': totalMinutes,
        'goals_per_match': response.isNotEmpty 
            ? (totalGoals / response.length).toStringAsFixed(2) 
            : '0.00',
      };
    } catch (e) {
      debugPrint('Error getting player total stats: $e');
      return null;
    }
  }

  /// Verificar si ya existen estadísticas para un partido
  Future<bool> matchHasStats(String matchId) async {
    try {
      final response = await _supabase
          .from('match_stats')
          .select('id')
          .eq('match_id', matchId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking match stats: $e');
      return false;
    }
  }

  /// Obtener el máximo goleador del equipo (para mostrar en cards)
  Future<TopScorer?> getTeamTopScorer(String teamId) async {
    try {
      final scorers = await getTeamTopScorers(teamId: teamId, limit: 1);
      return scorers.isNotEmpty ? scorers.first : null;
    } catch (e) {
      debugPrint('Error getting team top scorer: $e');
      return null;
    }
  }

  /// Obtener últimos partidos con estadísticas de un jugador
  Future<List<MatchStats>> getPlayerRecentStats({
    required String playerId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('match_stats')
          .select()
          .eq('player_id', playerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MatchStats.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting player recent stats: $e');
      return [];
    }
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// Obtener todas las categorías disponibles en el club
  Future<List<String>> getClubCategories(String clubId) async {
    try {
      final response = await _supabase
          .from('teams')
          .select('category')
          .eq('club_id', clubId)
          .not('category', 'is', null);

      // Extraer categorías únicas
      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      debugPrint('Error getting club categories: $e');
      return [];
    }
  }

  /// Actualizar la categoría de un equipo
  Future<bool> updateTeamCategory({
    required String teamId,
    required String category,
  }) async {
    try {
      await _supabase.from('teams').update({
        'category': category,
      }).eq('id', teamId);

      return true;
    } catch (e) {
      debugPrint('Error updating team category: $e');
      return false;
    }
  }
}
