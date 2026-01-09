/// ============================================================
/// MODELO: ChatChannel
/// ============================================================
/// Representa un canal de chat del equipo
/// ============================================================
library;

class ChatChannel {
  final String id;
  final String teamId;
  final ChatChannelType type;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatChannel({
    required this.id,
    required this.teamId,
    required this.type,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  /// Crea un ChatChannel desde un JSON de Supabase
  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      type: ChatChannelTypeExtension.fromString(json['type'] as String),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte un ChatChannel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'type': type.value,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Verifica si el usuario puede escribir en este canal
  /// (basado en el tipo de canal y el rol del usuario)
  bool canUserWrite(String userRole) {
    if (type == ChatChannelType.general) {
      return true; // Todos pueden escribir en el canal general
    } else if (type == ChatChannelType.announcement) {
      return ['coach', 'admin'].contains(userRole); // Solo coaches pueden escribir en anuncios
    }
    return false;
  }

  @override
  String toString() => 'ChatChannel(id: $id, name: $name, type: ${type.value})';
}

/// ============================================================
/// ENUM: ChatChannelType
/// ============================================================

enum ChatChannelType {
  announcement, // Tablón del Entrenador (solo lectura para padres)
  general, // Vestuario (chat libre)
}

extension ChatChannelTypeExtension on ChatChannelType {
  String get value {
    switch (this) {
      case ChatChannelType.announcement:
        return 'announcement';
      case ChatChannelType.general:
        return 'general';
    }
  }

  /// Nombre legible en español
  String get displayName {
    switch (this) {
      case ChatChannelType.announcement:
        return 'Avisos Oficiales';
      case ChatChannelType.general:
        return 'Vestuario';
    }
  }

  static ChatChannelType fromString(String value) {
    switch (value) {
      case 'announcement':
        return ChatChannelType.announcement;
      case 'general':
        return ChatChannelType.general;
      default:
        throw ArgumentError('Tipo de canal desconocido: $value');
    }
  }
}
