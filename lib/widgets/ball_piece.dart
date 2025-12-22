
import 'package:flutter/material.dart';

class BallPiece extends StatelessWidget {
  const BallPiece({super.key});

  @override
  Widget build(BuildContext context) {
    const double ballSize = 28.0;

    return const Icon(
      Icons.sports_soccer,
      size: ballSize,
      color: Colors.white,
      shadows: [
        Shadow(blurRadius: 6.0, color: Colors.black45)
      ],
    );
  }
}
