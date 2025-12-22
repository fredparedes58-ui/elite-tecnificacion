
import 'package:myapp/models/player_model.dart';

class Team {
  final String name;
  final String coach;
  final String? assistantCoach;
  final List<Player> players;

  Team({
    required this.name,
    required this.coach,
    this.assistantCoach,
    required this.players,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    var playerList = json['players'] as List;
    List<Player> players = playerList.map((i) => Player.fromJson(i)).toList();

    return Team(
      name: json['name'] as String,
      coach: json['coach'] as String,
      assistantCoach: json['assistantCoach'] as String?,
      players: players,
    );
  }
}
