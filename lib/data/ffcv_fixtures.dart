// ============================================================
// CALENDARIO COMPLETO FFCV - TEMPORADA 2025-2026
// ============================================================
// Datos extraídos de resultadosffcv.isquad.es
// Competición: F-8 Campo 1 (categoría A)
// ============================================================

class FFCVMatch {
  final String id;
  final int jornada;
  final String homeTeam;
  final String awayTeam;
  final String? score; // "1 - 3" o null si no se ha jugado
  final DateTime date;
  final String? time; // "19:15" o null
  final String location;
  final String? field; // "Campo 1", "Campo 2", etc.

  FFCVMatch({
    required this.id,
    required this.jornada,
    required this.homeTeam,
    required this.awayTeam,
    this.score,
    required this.date,
    this.time,
    required this.location,
    this.field,
  });

  bool get isPlayed => score != null && score!.isNotEmpty;
  int? get homeGoals {
    if (score == null) return null;
    final parts = score!.split(' - ');
    if (parts.length != 2) return null;
    return int.tryParse(parts[0].trim());
  }

  int? get awayGoals {
    if (score == null) return null;
    final parts = score!.split(' - ');
    if (parts.length != 2) return null;
    return int.tryParse(parts[1].trim());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jornada': jornada,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'score': score,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'field': field,
    };
  }

  factory FFCVMatch.fromMap(Map<String, dynamic> map) {
    return FFCVMatch(
      id: map['id'] as String,
      jornada: map['jornada'] as int,
      homeTeam: map['home_team'] as String,
      awayTeam: map['away_team'] as String,
      score: map['score'] as String?,
      date: DateTime.parse(map['date']),
      time: map['time'] as String?,
      location: map['location'] as String,
      field: map['field'] as String?,
    );
  }
}

// JORNADA 1
final List<FFCVMatch> jornada1 = [
  FFCVMatch(
    id: 'j1_1',
    jornada: 1,
    homeTeam: "Picassent C.F. 'A'",
    awayTeam: "C.D. Monte-Sión 'A'",
    score: '1 - 3',
    date: DateTime(2025, 10, 17),
    time: '19:15',
    location: 'Polideportivo Mpal. de Picassent',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j1_2',
    jornada: 1,
    homeTeam: "C.F. Fundació VCF 'A'",
    awayTeam: "Col. Salgui E.D.E. 'A'",
    score: '6 - 1',
    date: DateTime(2025, 10, 18),
    time: '09:00',
    location: 'Ciudad Dptva. Valencia CF',
    field: 'F-8 Campo 2(HA)',
  ),
  FFCVMatch(
    id: 'j1_3',
    jornada: 1,
    homeTeam: "C.D. San Marcelino 'A'",
    awayTeam: "C.D. Don Bosco 'A'",
    score: '6 - 1',
    date: DateTime(2025, 10, 18),
    time: '10:15',
    location: 'Campo Futbol San Marcelino',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j1_4',
    jornada: 1,
    homeTeam: "Equipo Casa (No asignado)",
    awayTeam: "Unió Benetússer-Favara C.F. 'A'",
    date: DateTime(2025, 10, 18),
    location: '',
  ),
  FFCVMatch(
    id: 'j1_5',
    jornada: 1,
    homeTeam: "F.B.C.D. Catarroja 'B'",
    awayTeam: "F.B.U.E. Atlètic Amistat 'A'",
    score: '2 - 1',
    date: DateTime(2025, 10, 19),
    time: '09:00',
    location: 'Campo Mundial 82',
    field: 'F-8 Campo 2 Catarroja(HA)',
  ),
  FFCVMatch(
    id: 'j1_6',
    jornada: 1,
    homeTeam: "C.F. Sporting Xirivella 'C'",
    awayTeam: "U.D. Alzira 'A'",
    score: '3 - 0',
    date: DateTime(2025, 10, 19),
    time: '12:00',
    location: 'Polideportivo Mpal. Ramón Sáez',
    field: 'F-8 Campo 3 Xirivella(HA)',
  ),
  FFCVMatch(
    id: 'j1_7',
    jornada: 1,
    homeTeam: "C.F.B. Ciutat de València 'A'",
    awayTeam: "Torrent C.F. 'C'",
    score: '2 - 2',
    date: DateTime(2025, 10, 19),
    time: '12:15',
    location: 'Campo Mpal. La Exposicion',
    field: 'F-8 Campo 1(HA)',
  ),
];

// JORNADA 2
final List<FFCVMatch> jornada2 = [
  FFCVMatch(
    id: 'j2_1',
    jornada: 2,
    homeTeam: "C.D. Don Bosco 'A'",
    awayTeam: "C.F. Fundació VCF 'A'",
    score: '0 - 20',
    date: DateTime(2025, 10, 25),
    time: '09:00',
    location: 'Campo Salesianos Don Bosco',
    field: 'F-8 Campo 2 Valencia(HA)',
  ),
  FFCVMatch(
    id: 'j2_2',
    jornada: 2,
    homeTeam: "F.B.U.E. Atlètic Amistat 'A'",
    awayTeam: "Picassent C.F. 'A'",
    score: '7 - 3',
    date: DateTime(2025, 10, 25),
    time: '09:00',
    location: 'Polideportivo Mpal. Quatre Carreres',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j2_3',
    jornada: 2,
    homeTeam: "Unió Benetússer-Favara C.F. 'A'",
    awayTeam: "C.F.B. Ciutat de València 'A'",
    score: '4 - 3',
    date: DateTime(2025, 10, 25),
    time: '11:00',
    location: 'Polideportivo Mpal. de Benetusser',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j2_4',
    jornada: 2,
    homeTeam: "U.D. Alzira 'A'",
    awayTeam: "C.D. San Marcelino 'A'",
    score: '5 - 2',
    date: DateTime(2025, 10, 25),
    time: '12:15',
    location: 'Campo Mpal. Venecia',
    field: 'F-8 Campo 3 Nacho Barberá(HA)',
  ),
  FFCVMatch(
    id: 'j2_5',
    jornada: 2,
    homeTeam: "Torrent C.F. 'C'",
    awayTeam: "F.B.C.D. Catarroja 'B'",
    score: '1 - 3',
    date: DateTime(2025, 10, 25),
    time: '13:15',
    location: 'Campo de Futbol Mpal. San Gregorio',
    field: 'F-8 Campo B1 Torrent(HA)',
  ),
  FFCVMatch(
    id: 'j2_6',
    jornada: 2,
    homeTeam: "C.D. Monte-Sión 'A'",
    awayTeam: "C.F. Sporting Xirivella 'C'",
    score: '1 - 0',
    date: DateTime(2025, 10, 26),
    time: '10:45',
    location: "Ciutat de L'Esport Parc Central",
    field: 'F-8 Campo 2A(HA)',
  ),
  FFCVMatch(
    id: 'j2_7',
    jornada: 2,
    homeTeam: "Col. Salgui E.D.E. 'A'",
    awayTeam: "Equipo Fuera (No asignado)",
    date: DateTime(2025, 10, 26),
    location: '',
  ),
];

// JORNADA 3
final List<FFCVMatch> jornada3 = [
  FFCVMatch(
    id: 'j3_1',
    jornada: 3,
    homeTeam: "F.B.C.D. Catarroja 'B'",
    awayTeam: "Unió Benetússer-Favara C.F. 'A'",
    score: '1 - 0',
    date: DateTime(2025, 10, 31),
    time: '20:15',
    location: 'Polideportivo Mpal. de Catarroja',
    field: 'F-8 Campo 2(HA)',
  ),
  FFCVMatch(
    id: 'j3_2',
    jornada: 3,
    homeTeam: "C.D. Don Bosco 'A'",
    awayTeam: "U.D. Alzira 'A'",
    score: '0 - 4',
    date: DateTime(2025, 11, 1),
    time: '09:00',
    location: 'Campo Salesianos Don Bosco',
    field: 'F-8 Campo 1 Valencia(HA)',
  ),
  FFCVMatch(
    id: 'j3_3',
    jornada: 3,
    homeTeam: "Picassent C.F. 'A'",
    awayTeam: "Torrent C.F. 'C'",
    score: '0 - 3',
    date: DateTime(2025, 11, 1),
    time: '09:00',
    location: 'Polideportivo Mpal. de Picassent',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j3_4',
    jornada: 3,
    homeTeam: "C.F.B. Ciutat de València 'A'",
    awayTeam: "Col. Salgui E.D.E. 'A'",
    score: '0 - 3',
    date: DateTime(2025, 11, 1),
    time: '09:00',
    location: 'Campo Mpal. La Exposicion',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j3_5',
    jornada: 3,
    homeTeam: "C.D. San Marcelino 'A'",
    awayTeam: "C.D. Monte-Sión 'A'",
    score: '0 - 2',
    date: DateTime(2025, 11, 1),
    time: '10:30',
    location: 'Campo Futbol San Marcelino',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j3_6',
    jornada: 3,
    homeTeam: "C.F. Fundació VCF 'A'",
    awayTeam: "Equipo Fuera (No asignado)",
    date: DateTime(2025, 11, 1),
    location: '',
  ),
  FFCVMatch(
    id: 'j3_7',
    jornada: 3,
    homeTeam: "C.F. Sporting Xirivella 'C'",
    awayTeam: "F.B.U.E. Atlètic Amistat 'A'",
    score: '1 - 2',
    date: DateTime(2025, 11, 2),
    time: '12:00',
    location: 'Polideportivo Mpal. Ramón Sáez',
    field: 'F-8 Campo 4 Xirivella(HA)',
  ),
];

// JORNADA 4
final List<FFCVMatch> jornada4 = [
  FFCVMatch(
    id: 'j4_1',
    jornada: 4,
    homeTeam: "Unió Benetússer-Favara C.F. 'A'",
    awayTeam: "Picassent C.F. 'A'",
    score: '6 - 1',
    date: DateTime(2025, 11, 7),
    time: '18:45',
    location: 'Polideportivo Mpal. de Benetússer',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j4_2',
    jornada: 4,
    homeTeam: "F.B.U.E. Atlètic Amistat 'A'",
    awayTeam: "C.D. San Marcelino 'A'",
    score: '2 - 2',
    date: DateTime(2025, 11, 8),
    time: '09:00',
    location: 'Polideportivo Mpal. Quatre Carreres',
    field: 'F-8 Campo 1(HA)',
  ),
  FFCVMatch(
    id: 'j4_3',
    jornada: 4,
    homeTeam: "Col. Salgui E.D.E. 'A'",
    awayTeam: "F.B.C.D. Catarroja 'B'",
    score: '3 - 6',
    date: DateTime(2025, 11, 8),
    time: '09:00',
    location: 'Campo Futbol San Marcelino',
    field: 'F-8 Campo 2(HA)',
  ),
  FFCVMatch(
    id: 'j4_4',
    jornada: 4,
    homeTeam: "U.D. Alzira 'A'",
    awayTeam: "C.F. Fundació VCF 'A'",
    score: '2 - 6',
    date: DateTime(2025, 11, 8),
    time: '11:45',
    location: 'Campo Mpal. Venecia',
    field: 'F-8 Campo 1 Alzira(HA)',
  ),
  FFCVMatch(
    id: 'j4_5',
    jornada: 4,
    homeTeam: "Equipo Casa (No asignado)",
    awayTeam: "C.F.B. Ciutat de València 'A'",
    date: DateTime(2025, 11, 8),
    location: '',
  ),
  FFCVMatch(
    id: 'j4_6',
    jornada: 4,
    homeTeam: "Torrent C.F. 'C'",
    awayTeam: "C.F. Sporting Xirivella 'C'",
    score: '1 - 3',
    date: DateTime(2025, 11, 9),
    time: '09:00',
    location: 'Campo de Futbol Mpal. San Gregorio',
    field: 'F-8 Campo B1 Torrent(HA)',
  ),
];

// Todas las jornadas (aquí solo están las primeras 4 como ejemplo)
// Necesitarás agregar las jornadas 5-26 con los mismos datos
final List<List<FFCVMatch>> allFFCVFixtures = [
  jornada1,
  jornada2,
  jornada3,
  jornada4,
  // TODO: Agregar jornadas 5-26
];

// Obtener todos los partidos en una lista plana
List<FFCVMatch> getAllFFCVMatches() {
  return allFFCVFixtures.expand((jornada) => jornada).toList();
}

// Obtener partidos por jornada
List<FFCVMatch> getMatchesByJornada(int jornada) {
  if (jornada < 1 || jornada > allFFCVFixtures.length) return [];
  return allFFCVFixtures[jornada - 1];
}

// Obtener partidos de un equipo específico
List<FFCVMatch> getMatchesByTeam(String teamName) {
  return getAllFFCVMatches().where((match) {
    return match.homeTeam.contains(teamName) || match.awayTeam.contains(teamName);
  }).toList();
}
