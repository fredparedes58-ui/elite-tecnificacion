

class Player {
  final String name;
  final String number;
  final int level;
  final String position1;
  final String position2;
  final String avatarAsset;
  final PlayerStats stats;

  Player({
    required this.name,
    required this.number,
    required this.level,
    required this.position1,
    required this.position2,
    required this.avatarAsset,
    required this.stats,
  });
}

class PlayerStats {
  final int media;
  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;
  final int goals;
  final int asst;

  PlayerStats({
    required this.media,
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
    required this.goals,
    required this.asst,
  });

  List<double> get statsList =>
      [pac / 100, sho / 100, pas / 100, dri / 100, def / 100, phy / 100];
}
