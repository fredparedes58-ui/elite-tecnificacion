
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';

// Representa una instantánea completa de la pizarra táctica en un momento dado.
class TacticalSession {
  final String id;
  final String name;
  // CORRECCIÓN: Ahora guardamos también la lista de titulares y suplentes
  final List<Player> starters;
  final List<Player> substitutes;
  final Map<String, Offset> starterPositions;
  final Offset ballPosition;
  final List<List<Offset?>> lines;

  TacticalSession({
    required this.id,
    required this.name,
    required this.starters,
    required this.substitutes,
    required this.starterPositions,
    required this.ballPosition,
    required this.lines,
  });
}
