
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
      // Usamos AssetImage para cargar la imagen desde los assets locales
      backgroundImage: player.image.isNotEmpty ? AssetImage(player.image) : null,
      // Si no hay imagen, mostramos la inicial del nombre del jugador
      child: player.image.isEmpty
          ? Text(
              player.name.isNotEmpty ? player.name.substring(0, 1) : ''
            )
          : null,
    );
  }
}
