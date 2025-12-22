
class PlayerStats {
  final int goals;
  final int assists;
  final int matchesPlayed;
  final Map<String, double> skills;

  PlayerStats({
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.skills = const {},
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      goals: map['goals'] ?? 0,
      assists: map['assists'] ?? 0,
      matchesPlayed: map['matchesPlayed'] ?? 0,
      skills: Map<String, double>.from(map['skills'] ?? {}),
    );
  }
}
