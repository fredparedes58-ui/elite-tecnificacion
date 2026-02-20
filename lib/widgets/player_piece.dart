
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';

// Este es un widget puramente presentacional. Es "tonto".
// Su única responsabilidad es mostrar la apariencia del jugador.
class PlayerPiece extends StatelessWidget {
  final Player player;
  final double size;
  final bool isGhost;
  final bool isSelected;

  const PlayerPiece({
    super.key,
    required this.player,
    this.size = 60.0,
    this.isGhost = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el color del borde basado en el estado
    Color borderColor = Colors.white;
    double borderWidth = 2;
    List<BoxShadow> shadows = isGhost
        ? []
        : [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))];

    if (isSelected) {
      borderColor = Colors.amber;
      borderWidth = 4;
      shadows = [
        BoxShadow(
          color: Colors.amber.withValues(alpha: 0.6),
          blurRadius: 15,
          spreadRadius: 3,
        ),
        const BoxShadow(
          color: Colors.black54,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
    }

    final playerAvatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: player.image.startsWith('http')
                      ? NetworkImage(player.image)
                      : AssetImage(player.image) as ImageProvider,
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: shadows,
              ),
            ),
            // Indicador de selección
            if (isSelected)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
          ],
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

    // Devolvemos el avatar envuelto en un Draggable
    return Draggable<Player>(
      data: player,
      // Feedback mientras se arrastra (lo que ves moviendo)
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: PlayerPiece(player: player, size: size, isGhost: true, isSelected: isSelected),
        ),
      ),
      // Lo que queda en el lugar original mientras arrastras
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: playerAvatar,
      ),
      // Widget normal
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: playerAvatar,
      ),
    );
  }
}
