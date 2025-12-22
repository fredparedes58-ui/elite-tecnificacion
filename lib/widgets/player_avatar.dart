import 'package:flutter/material.dart';
import '../models/player_model.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.player, this.radius = 25});

  final Player player;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(player.avatarAsset),
      child: player.avatarAsset.isEmpty
          ? Text(player.name.substring(0, 1))
          : null,
    );
  }
}
