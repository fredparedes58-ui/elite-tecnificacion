// ============================================================
// MODELO: MATCH STATS (Estadísticas de Partido)
// ============================================================
// Representa las estadísticas individuales de un jugador en un partido
// ============================================================

class MatchStats {
  final String id;
  final String matchId;
  final String playerId;
  final String teamId;
  final int goals;
  final int assists;
  final int minutesPlayed;
  final int yellowCards;
  final int redCards;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchStats({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.teamId,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde JSON (Supabase)
  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      playerId: json['player_id'] as String,
      teamId: json['team_id'] as String,
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      minutesPlayed: json['minutes_played'] as int? ?? 0,
      yellowCards: json['yellow_cards'] as int? ?? 0,
      redCards: json['red_cards'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'player_id': playerId,
      'team_id': teamId,
      'goals': goals,
      'assists': assists,
      'minutes_played': minutesPlayed,
      'yellow_cards': yellowCards,
      'red_cards': redCards,
    };
  }

  // Crear copia con modificaciones
  MatchStats copyWith({
    String? id,
    String? matchId,
    String? playerId,
    String? teamId,
    int? goals,
    int? assists,
    int? minutesPlayed,
    int? yellowCards,
    int? redCards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchStats(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// MODELO: TOP SCORER (Goleador con estadísticas acumuladas)
// ============================================================
class TopScorer {
  final String playerId;
  final String playerName;
  final String? photoUrl;
  final String? position;
  final int? jerseyNumber;
  final String? teamId;
  final String? teamName;
  final String? category;
  final int totalGoals;
  final int totalAssists;
  final int matchesPlayed;
  final int totalMinutes;
  final double goalsPerMatch;

  TopScorer({
    required this.playerId,
    required this.playerName,
    this.photoUrl,
    this.position,
    this.jerseyNumber,
    this.teamId,
    this.teamName,
    this.category,
    required this.totalGoals,
    required this.totalAssists,
    required this.matchesPlayed,
    this.totalMinutes = 0,
    this.goalsPerMatch = 0.0,
  });

  // Crear desde JSON (Supabase)
  factory TopScorer.fromJson(Map<String, dynamic> json) {
    return TopScorer(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      photoUrl: json['photo_url'] as String?,
      position: json['position'] as String?,
      jerseyNumber: json['jersey_number'] as int?,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      category: json['category'] as String?,
      totalGoals: json['total_goals'] as int? ?? 0,
      totalAssists: json['total_assists'] as int? ?? 0,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
      goalsPerMatch: (json['goals_per_match'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Posición en el ranking (1 = campeón)
  String getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  // Color para el ranking
  String getRankColor(int rank) {
    switch (rank) {
      case 1:
        return '#FFD700'; // Oro
      case 2:
        return '#C0C0C0'; // Plata
      case 3:
        return '#CD7F32'; // Bronce
      default:
        return '#FFFFFF'; // Blanco
    }
  }
}

// ============================================================
// MODELO: PLAYER STATS INPUT (Para la pantalla de entrada)
// ============================================================
class PlayerStatsInput {
  final String playerId;
  final String playerName;
  final String? image;
  final String? role;
  int goals;
  int assists;
  int minutesPlayed;

  PlayerStatsInput({
    required this.playerId,
    required this.playerName,
    this.image,
    this.role,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
  });

  // Convertir a MatchStats para guardar
  Map<String, dynamic> toMatchStats({
    required String matchId,
    required String teamId,
  }) {
    return {
      'match_id': matchId,
      'player_id': playerId,
      'team_id': teamId,
      'goals': goals,
      'assists': assists,
      'minutes_played': minutesPlayed,
    };
  }
}
