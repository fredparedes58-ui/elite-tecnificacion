// ============================================================
// SOCIAL POST MODEL
// ============================================================
// Modelo para posts del feed social tipo Instagram
// ============================================================

class SocialPost {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String teamId;
  final String userId;
  final String? contentText;
  final String mediaUrl;
  final MediaType mediaType;
  final String? thumbnailUrl;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;
  
  // Campos adicionales de la vista enriquecida
  final String? authorName;
  final String? authorRole;
  final bool? isLikedByMe;

  SocialPost({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.teamId,
    required this.userId,
    this.contentText,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    this.authorName,
    this.authorRole,
    this.isLikedByMe,
  });

  // Factory constructor desde JSON (Supabase)
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      contentText: json['content_text'] as String?,
      mediaUrl: json['media_url'] as String,
      mediaType: MediaType.fromString(json['media_type'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      authorName: json['author_name'] as String?,
      authorRole: json['author_role'] as String?,
      isLikedByMe: json['is_liked_by_me'] as bool?,
    );
  }

  // Convertir a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'team_id': teamId,
      'user_id': userId,
      'content_text': contentText,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      'thumbnail_url': thumbnailUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_pinned': isPinned,
    };
  }

  // Método para crear un nuevo post (sin id ni timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'team_id': teamId,
      'user_id': userId,
      'content_text': contentText,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      'thumbnail_url': thumbnailUrl,
    };
  }

  // CopyWith para inmutabilidad
  SocialPost copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? teamId,
    String? userId,
    String? contentText,
    String? mediaUrl,
    MediaType? mediaType,
    String? thumbnailUrl,
    int? likesCount,
    int? commentsCount,
    bool? isPinned,
    String? authorName,
    String? authorRole,
    bool? isLikedByMe,
  }) {
    return SocialPost(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      contentText: contentText ?? this.contentText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isPinned: isPinned ?? this.isPinned,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  // Obtener tiempo relativo (ej: "hace 2h")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).floor()}sem';
    } else if (difference.inDays < 365) {
      return 'Hace ${(difference.inDays / 30).floor()}mes';
    } else {
      return 'Hace ${(difference.inDays / 365).floor()}año';
    }
  }
}

// ============================================================
// ENUM: MEDIA TYPE
// ============================================================

enum MediaType {
  image('image'),
  video('video');

  final String value;
  const MediaType(this.value);

  static MediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      default:
        throw Exception('Tipo de media no válido: $value');
    }
  }
}

// ============================================================
// MODELO PARA CREAR POST (DTO)
// ============================================================

class CreateSocialPostDto {
  final String teamId;
  final String userId;
  final String? contentText;
  final String mediaUrl;
  final MediaType mediaType;
  final String? thumbnailUrl;

  CreateSocialPostDto({
    required this.teamId,
    required this.userId,
    this.contentText,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'user_id': userId,
      'content_text': contentText,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      'thumbnail_url': thumbnailUrl,
    };
  }
}
