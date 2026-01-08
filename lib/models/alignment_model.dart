import 'package:flutter/material.dart';

class Alignment {
  final String id;
  final String name;
  final String formation; // Ejemplo: "4-4-2", "4-3-3", etc.
  final Map<String, PlayerPosition> playerPositions; // playerId -> position
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isCustom; // true si es creada por el usuario

  Alignment({
    required this.id,
    required this.name,
    required this.formation,
    Map<String, PlayerPosition>? playerPositions,
    this.createdAt,
    this.updatedAt,
    this.isCustom = false,
  }) : playerPositions = playerPositions ?? {};

  // Factory desde JSON (Supabase)
  factory Alignment.fromJson(Map<String, dynamic> json) {
    Map<String, PlayerPosition> positions = {};
    
    if (json['player_positions'] != null) {
      final positionsData = json['player_positions'] as Map<String, dynamic>;
      positionsData.forEach((playerId, posData) {
        if (posData is Map<String, dynamic>) {
          positions[playerId] = PlayerPosition.fromJson(posData);
        }
      });
    }

    return Alignment(
      id: json['id'] as String,
      name: json['name'] as String,
      formation: json['formation'] as String? ?? '4-4-2',
      playerPositions: positions,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  // Convertir a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formation': formation,
      'player_positions': playerPositions.map(
        (playerId, position) => MapEntry(playerId, position.toJson()),
      ),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_custom': isCustom,
    };
  }

  Alignment copyWith({
    String? id,
    String? name,
    String? formation,
    Map<String, PlayerPosition>? playerPositions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCustom,
  }) {
    return Alignment(
      id: id ?? this.id,
      name: name ?? this.name,
      formation: formation ?? this.formation,
      playerPositions: playerPositions ?? this.playerPositions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Representa la posición de un jugador en la alineación
class PlayerPosition {
  final Offset offset; // Posición en el campo
  final String? role; // Rol en esta posición (opcional)

  PlayerPosition({
    required this.offset,
    this.role,
  });

  factory PlayerPosition.fromJson(Map<String, dynamic> json) {
    return PlayerPosition(
      offset: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'role': role,
    };
  }
}
