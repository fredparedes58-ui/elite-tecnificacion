
import 'package:flutter/material.dart';

class Formation {
  final String id;
  final String name;
  final Map<String, Offset> playerPositions;

  Formation({
    required this.id,
    required this.name,
    required this.playerPositions,
  });
}
