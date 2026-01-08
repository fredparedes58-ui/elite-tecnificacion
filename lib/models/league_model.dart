class TeamStanding {
  final int position;
  final String club;
  final int games; // J
  final int wins; // G
  final int draws; // E
  final int losses; // P
  final int goalsFor; // GF
  final int goalsAgainst; // GC
  final int goalDifference; // DIF
  final int points; // PT
  final String? logoUrl;

  TeamStanding({
    required this.position,
    required this.club,
    required this.games,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.logoUrl,
  });

  // Calculated properties
  double get winPercentage => games > 0 ? (wins / games) * 100 : 0;
  double get drawPercentage => games > 0 ? (draws / games) * 100 : 0;
  double get lossPercentage => games > 0 ? (losses / games) * 100 : 0;
  double get avgGoalsFor => games > 0 ? goalsFor / games : 0;
  double get avgGoalsAgainst => games > 0 ? goalsAgainst / games : 0;
}
