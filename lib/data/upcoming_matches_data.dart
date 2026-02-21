// Datos de próximos partidos de la liga FFCV
class UpcomingMatch {
  final String homeTeam;
  final String awayTeam;
  final String date;
  final String time;
  final String location;

  UpcomingMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.time,
    required this.location,
  });
}

// Próximo partido basado en la liga FFCV - Fundación Valencia
final UpcomingMatch nextMatch = UpcomingMatch(
  homeTeam: 'C.F. Fundació VCF \'A\'',
  awayTeam: 'F.B.U.E. Atlètic Amistat \'A\'',
  date: 'SÁBADO, 11 DE ENERO',
  time: '16:00',
  location: 'Ciutat Esportiva de Paterna',
);
