
import 'package:myapp/models/player_stats.dart';

class Player {
  final String name;
  final String? role;
  final bool isStarter;
  final String image;
  final PlayerStats stats;

  Player({
    required this.name,
    this.role,
    required this.isStarter,
    required this.image,
    PlayerStats? stats,
  }) : stats = stats ?? PlayerStats();

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] as String,
      role: json['role'] as String?,
      isStarter: json['isStarter'] as bool,
      image: json['image'] as String,
      stats: json['stats'] != null ? PlayerStats.fromMap(json['stats']) : PlayerStats(),
    );
  }
}
