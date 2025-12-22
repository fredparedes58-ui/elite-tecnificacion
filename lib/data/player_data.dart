class Player {
  final String name;
  final int number;
  final String position;

  Player({required this.name, required this.number, required this.position});
}

class Team {
  final String name;
  final List<Player> players;

  Team({required this.name, required this.players});
}

final List<Team> teams = [
  Team(
    name: 'Real Madrid',
    players: [
      Player(name: 'Courtois', number: 1, position: 'GK'),
      Player(name: 'Carvajal', number: 2, position: 'DF'),
      Player(name: 'Militão', number: 3, position: 'DF'),
      Player(name: 'Alaba', number: 4, position: 'DF'),
      Player(name: 'Vallejo', number: 5, position: 'DF'),
      Player(name: 'Nacho', number: 6, position: 'DF'),
      Player(name: 'Hazard', number: 7, position: 'FW'),
      Player(name: 'Kroos', number: 8, position: 'MF'),
      Player(name: 'Benzema', number: 9, position: 'FW'),
      Player(name: 'Modric', number: 10, position: 'MF'),
      Player(name: 'Asensio', number: 11, position: 'FW'),
    ],
  ),
];
