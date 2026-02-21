/// ============================================================
/// MODELO: ChatMessage
/// ============================================================
/// Representa un mensaje en un canal de chat
/// ============================================================
library;

class ChatMessage {
  final String id;
  final String channelId;
  final String userId;
  final String content;
  final String? mediaUrl;
  final ChatMediaType? mediaType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Para mensajes privados
  final String? recipientId; // ID del destinatario en mensajes privados
  final bool isPrivate; // Si es mensaje privado (uno a uno)

  // Información del usuario (desde la vista detailed)
  final String? userName;
  final String? userAvatarUrl;
  final String? userRole;
  final String? playerRepresentedId; // ID del jugador si es representante

  // Información del canal (desde la vista detailed)
  final String? channelType;
  final String? channelName;
  
  // Para ubicaciones
  final double? latitude;
  final double? longitude;

  ChatMessage({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.updatedAt,
    this.recipientId,
    this.isPrivate = false,
    this.userName,
    this.userAvatarUrl,
    this.userRole,
    this.playerRepresentedId,
    this.channelType,
    this.channelName,
    this.latitude,
    this.longitude,
  });

  /// Crea un ChatMessage desde un JSON de Supabase
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] != null
          ? ChatMediaTypeExtension.fromString(json['media_type'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      recipientId: json['recipient_id'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      userRole: json['user_role'] as String?,
      playerRepresentedId: json['player_represented_id'] as String?,
      channelType: json['channel_type'] as String?,
      channelName: json['channel_name'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  /// Convierte un ChatMessage a JSON para insertar
  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'user_id': userId,
      'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType!.value,
      if (recipientId != null) 'recipient_id': recipientId,
      'is_private': isPrivate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Verifica si el mensaje tiene media adjunto
  bool get hasMedia => mediaUrl != null && mediaType != null;

  /// Verifica si el mensaje es una imagen
  bool get isImage => mediaType == ChatMediaType.image;

  /// Verifica si el mensaje es un video
  bool get isVideo => mediaType == ChatMediaType.video;

  /// Verifica si el mensaje es un audio
  bool get isAudio => mediaType == ChatMediaType.audio;

  /// Verifica si el mensaje es un documento
  bool get isDocument => mediaType == ChatMediaType.document;

  /// Verifica si el mensaje es una ubicación
  bool get isLocation => mediaType == ChatMediaType.location;

  /// Obtiene el tiempo relativo del mensaje (ej: "hace 5 min")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} min';
    } else {
      return 'ahora';
    }
  }

  @override
  String toString() => 'ChatMessage(id: $id, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
}

/// ============================================================
/// ENUM: ChatMediaType
/// ============================================================

enum ChatMediaType {
  image,
  video,
  audio,
  document,
  location,
}

extension ChatMediaTypeExtension on ChatMediaType {
  String get value {
    switch (this) {
      case ChatMediaType.image:
        return 'image';
      case ChatMediaType.video:
        return 'video';
      case ChatMediaType.audio:
        return 'audio';
      case ChatMediaType.document:
        return 'document';
      case ChatMediaType.location:
        return 'location';
    }
  }

  String get displayName {
    switch (this) {
      case ChatMediaType.image:
        return '📷 Foto';
      case ChatMediaType.video:
        return '🎥 Video';
      case ChatMediaType.audio:
        return '🎤 Audio';
      case ChatMediaType.document:
        return '📄 Documento';
      case ChatMediaType.location:
        return '📍 Ubicación';
    }
  }

  static ChatMediaType fromString(String value) {
    switch (value) {
      case 'image':
        return ChatMediaType.image;
      case 'video':
        return ChatMediaType.video;
      case 'audio':
        return ChatMediaType.audio;
      case 'document':
        return ChatMediaType.document;
      case 'location':
        return ChatMediaType.location;
      default:
        throw ArgumentError('Tipo de media desconocido: $value');
    }
  }
}

/// ============================================================
/// DTO: CreateChatMessageDto
/// ============================================================
/// DTO para crear un nuevo mensaje
/// ============================================================

class CreateChatMessageDto {
  final String channelId;
  final String content;
  final String? mediaUrl;
  final ChatMediaType? mediaType;
  final String? recipientId;
  final bool isPrivate;
  final double? latitude;
  final double? longitude;

  CreateChatMessageDto({
    required this.channelId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.recipientId,
    this.isPrivate = false,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType!.value,
      if (recipientId != null) 'recipient_id': recipientId,
      'is_private': isPrivate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
