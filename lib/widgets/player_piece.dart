
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';

// Este es un widget puramente presentacional. Es "tonto".
// Su única responsabilidad es mostrar la apariencia del jugador.
class PlayerPiece extends StatelessWidget {
  final Player player;
  final double size;
  final bool isGhost;

  const PlayerPiece({super.key, required this.player, this.size = 60.0, this.isGhost = false});

  @override
  Widget build(BuildContext context) {
    final playerAvatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(player.image),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: isGhost
                ? []
                : [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        const SizedBox(height: 4),
        // El "fantasma" (la pieza que se arrastra) no necesita nombre
        if (!isGhost)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((255 * 0.7).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              player.name,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    // Devolvemos el avatar envuelto en un Draggable. 
    // No tiene lógica de posición, solo proporciona el "Player" como dato.
    return Draggable<Player>(
      data: player,
      // El feedback es la apariencia de la pieza mientras se arrastra
      feedback: PlayerPiece(player: player, size: size + 10, isGhost: true),
      // Cuando se empieza a arrastrar, el widget original se reemplaza por un SizedBox
      childWhenDragging: SizedBox(width: size, height: size + 20), // Placeholder para mantener el layout
      child: playerAvatar,
    );
  }
}
