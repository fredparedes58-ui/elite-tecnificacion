
class PlayerStats {
  final int goals;
  final int assists;
  final int matchesPlayed;
  final Map<String, double> skills;
  
  // Estadísticas de rendimiento (0-100)
  final double velocidad; // VELOCIDAD
  final double tecnica;   // TÉCN
  final double fisico;    // FÍSICO
  final double mental;    // MENTAL
  final double tactico;   // TÁCTICO

  PlayerStats({
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.skills = const {},
    this.velocidad = 0,
    this.tecnica = 0,
    this.fisico = 0,
    this.mental = 0,
    this.tactico = 0,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      goals: map['goals'] ?? 0,
      assists: map['assists'] ?? 0,
      matchesPlayed: map['matchesPlayed'] ?? 0,
      skills: Map<String, double>.from(map['skills'] ?? {}),
      velocidad: (map['velocidad'] ?? map['speed'] ?? 0).toDouble(),
      tecnica: (map['tecnica'] ?? map['technique'] ?? 0).toDouble(),
      fisico: (map['fisico'] ?? map['physical'] ?? 0).toDouble(),
      mental: (map['mental'] ?? 0).toDouble(),
      tactico: (map['tactico'] ?? map['tactical'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goals': goals,
      'assists': assists,
      'matchesPlayed': matchesPlayed,
      'skills': skills,
      'velocidad': velocidad,
      'tecnica': tecnica,
      'fisico': fisico,
      'mental': mental,
      'tactico': tactico,
    };
  }

  /// Calcula la puntuación general (promedio de todas las estadísticas)
  double get generalScore {
    final total = velocidad + tecnica + fisico + mental + tactico;
    return total / 5;
  }

  /// Crea una copia con valores actualizados
  PlayerStats copyWith({
    int? goals,
    int? assists,
    int? matchesPlayed,
    Map<String, double>? skills,
    double? velocidad,
    double? tecnica,
    double? fisico,
    double? mental,
    double? tactico,
  }) {
    return PlayerStats(
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      skills: skills ?? this.skills,
      velocidad: velocidad ?? this.velocidad,
      tecnica: tecnica ?? this.tecnica,
      fisico: fisico ?? this.fisico,
      mental: mental ?? this.mental,
      tactico: tactico ?? this.tactico,
    );
  }
}
