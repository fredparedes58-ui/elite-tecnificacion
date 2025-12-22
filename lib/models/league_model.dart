class TeamStanding {
  final int position;
  final String club;
  final int points;
  final String? logoUrl;

  TeamStanding({
    required this.position,
    required this.club,
    required this.points,
    this.logoUrl,
  });
}
