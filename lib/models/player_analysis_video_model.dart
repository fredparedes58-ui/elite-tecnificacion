// ============================================================
// MODELO: VIDEO DE ANÁLISIS DE JUGADOR
// ============================================================
// Videos privados del entrenador para análisis técnico individual
// ============================================================

class PlayerAnalysisVideo {
  final String id;
  final String playerId;
  final String coachId;
  final String teamId;
  
  // Video info
  final String videoUrl; // HLS playlist URL
  final String? thumbnailUrl;
  final String videoGuid; // Bunny Stream GUID
  
  // Metadata
  final String title;
  final String? comments;
  final String? analysisType; // 'technique', 'positioning', 'decision_making', etc.
  final int? durationSeconds;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Extra info (from joins/views)
  final String? playerName;
  final String? playerAvatar;
  final String? coachName;
  final String? coachAvatar;
  final String? teamName;

  PlayerAnalysisVideo({
    required this.id,
    required this.playerId,
    required this.coachId,
    required this.teamId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.videoGuid,
    required this.title,
    this.comments,
    this.analysisType,
    this.durationSeconds,
    required this.createdAt,
    this.updatedAt,
    this.playerName,
    this.playerAvatar,
    this.coachName,
    this.coachAvatar,
    this.teamName,
  });

  // ==========================================
  // FACTORY: DESDE SUPABASE
  // ==========================================

  factory PlayerAnalysisVideo.fromJson(Map<String, dynamic> json) {
    return PlayerAnalysisVideo(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      coachId: json['coach_id'] as String,
      teamId: json['team_id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoGuid: json['video_guid'] as String,
      title: json['title'] as String,
      comments: json['comments'] as String?,
      analysisType: json['analysis_type'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Extra fields from detailed view
      playerName: json['player_name'] as String?,
      playerAvatar: json['player_avatar'] as String?,
      coachName: json['coach_name'] as String?,
      coachAvatar: json['coach_avatar'] as String?,
      teamName: json['team_name'] as String?,
    );
  }

  // ==========================================
  // MÉTODO: A JSON PARA SUPABASE
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'coach_id': coachId,
      'team_id': teamId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'video_guid': videoGuid,
      'title': title,
      'comments': comments,
      'analysis_type': analysisType,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ==========================================
  // COPYWITH
  // ==========================================

  PlayerAnalysisVideo copyWith({
    String? id,
    String? playerId,
    String? coachId,
    String? teamId,
    String? videoUrl,
    String? thumbnailUrl,
    String? videoGuid,
    String? title,
    String? comments,
    String? analysisType,
    int? durationSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? playerName,
    String? playerAvatar,
    String? coachName,
    String? coachAvatar,
    String? teamName,
  }) {
    return PlayerAnalysisVideo(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      coachId: coachId ?? this.coachId,
      teamId: teamId ?? this.teamId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoGuid: videoGuid ?? this.videoGuid,
      title: title ?? this.title,
      comments: comments ?? this.comments,
      analysisType: analysisType ?? this.analysisType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      coachName: coachName ?? this.coachName,
      coachAvatar: coachAvatar ?? this.coachAvatar,
      teamName: teamName ?? this.teamName,
    );
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Duración formateada (ej: "2:34")
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Tipo de análisis legible
  String get analysisTypeLabel {
    switch (analysisType) {
      case 'technique':
        return 'Técnica';
      case 'positioning':
        return 'Posicionamiento';
      case 'decision_making':
        return 'Toma de Decisiones';
      case 'fitness':
        return 'Condición Física';
      case 'mental':
        return 'Aspecto Mental';
      case 'recovery':
        return 'Recuperación';
      default:
        return 'General';
    }
  }

  /// Tiempo desde la creación (ej: "Hace 2 días")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Hace ${years} año${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months} mes${months > 1 ? 'es' : ''}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }
}

// ============================================================
// MODELO: VIDEO TÁCTICO (PARA PIZARRA)
// ============================================================

class TacticalVideo {
  final String id;
  final String? tacticalSessionId;
  final String? alignmentId;
  final String teamId;
  final String coachId;
  
  // Video info
  final String videoUrl;
  final String? thumbnailUrl;
  final String videoGuid;
  
  // Metadata
  final String title;
  final String? description;
  final String videoType; // 'reference', 'real_match', 'training'
  final int? durationSeconds;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Extra info (from joins)
  final String? tacticalSessionName;
  final String? alignmentName;
  final String? coachName;
  final String? teamName;

  TacticalVideo({
    required this.id,
    this.tacticalSessionId,
    this.alignmentId,
    required this.teamId,
    required this.coachId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.videoGuid,
    required this.title,
    this.description,
    this.videoType = 'reference',
    this.durationSeconds,
    required this.createdAt,
    this.updatedAt,
    this.tacticalSessionName,
    this.alignmentName,
    this.coachName,
    this.teamName,
  });

  factory TacticalVideo.fromJson(Map<String, dynamic> json) {
    return TacticalVideo(
      id: json['id'] as String,
      tacticalSessionId: json['tactical_session_id'] as String?,
      alignmentId: json['alignment_id'] as String?,
      teamId: json['team_id'] as String,
      coachId: json['coach_id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoGuid: json['video_guid'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      videoType: json['video_type'] as String? ?? 'reference',
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      tacticalSessionName: json['tactical_session_name'] as String?,
      alignmentName: json['alignment_name'] as String?,
      coachName: json['coach_name'] as String?,
      teamName: json['team_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tactical_session_id': tacticalSessionId,
      'alignment_id': alignmentId,
      'team_id': teamId,
      'coach_id': coachId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'video_guid': videoGuid,
      'title': title,
      'description': description,
      'video_type': videoType,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get videoTypeLabel {
    switch (videoType) {
      case 'reference':
        return 'Referencia Profesional';
      case 'real_match':
        return 'Partido Real';
      case 'training':
        return 'Entrenamiento';
      default:
        return 'General';
    }
  }
}
