import 'package:flutter/material.dart';

/// ============================================================
/// MODELO: AnalysisEvent
/// ============================================================
/// Representa un evento marcado durante el análisis de video
/// con soporte para voice tagging y telestration
/// ============================================================

class AnalysisEvent {
  final String id;
  final String? matchId;
  final String? teamId;
  final String? playerId;
  final String? coachId;

  // Información del Tiempo
  final int matchTimestamp; // Segundos desde el pitido inicial (tiempo real del partido)
  final int? videoTimestamp; // Segundos desde el inicio del video (puede ser null si es Live)
  final String? videoGuid;

  // Información del Evento
  final String eventType;
  final String? eventTitle;

  // Voice Tagging
  final String? voiceTranscript;
  final double? voiceConfidence;

  // Telestration
  final String? drawingUrl;
  final Map<String, dynamic>? drawingData;

  // Metadata
  final String? notes;
  final List<String>? tags;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Información adicional (de la vista detallada)
  final String? playerName;
  final String? playerAvatar;
  final int? playerNumber;
  final String? coachName;
  final String? coachAvatar;
  final String? teamName;
  final String? teamBadge;

  AnalysisEvent({
    required this.id,
    this.matchId,
    this.teamId,
    this.playerId,
    this.coachId,
    required this.matchTimestamp,
    this.videoTimestamp,
    this.videoGuid,
    required this.eventType,
    this.eventTitle,
    this.voiceTranscript,
    this.voiceConfidence,
    this.drawingUrl,
    this.drawingData,
    this.notes,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.playerName,
    this.playerAvatar,
    this.playerNumber,
    this.coachName,
    this.coachAvatar,
    this.teamName,
    this.teamBadge,
  });

  /// Crea un evento desde JSON (Supabase)
  factory AnalysisEvent.fromJson(Map<String, dynamic> json) {
    return AnalysisEvent(
      id: json['id'] as String,
      matchId: json['match_id'] as String?,
      teamId: json['team_id'] as String?,
      playerId: json['player_id'] as String?,
      coachId: json['coach_id'] as String?,
      matchTimestamp: json['match_timestamp'] as int? ?? json['video_timestamp'] as int? ?? 0,
      videoTimestamp: json['video_timestamp'] as int?,
      videoGuid: json['video_guid'] as String?,
      eventType: json['event_type'] as String,
      eventTitle: json['event_title'] as String?,
      voiceTranscript: json['voice_transcript'] as String?,
      voiceConfidence: json['voice_confidence'] != null
          ? (json['voice_confidence'] as num).toDouble()
          : null,
      drawingUrl: json['drawing_url'] as String?,
      drawingData: json['drawing_data'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      playerName: json['player_name'] as String?,
      playerAvatar: json['player_avatar'] as String?,
      playerNumber: json['player_number'] as int?,
      coachName: json['coach_name'] as String?,
      coachAvatar: json['coach_avatar'] as String?,
      teamName: json['team_name'] as String?,
      teamBadge: json['team_badge'] as String?,
    );
  }

  /// Convierte el evento a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'team_id': teamId,
      'player_id': playerId,
      'coach_id': coachId,
      'match_timestamp': matchTimestamp,
      'video_timestamp': videoTimestamp,
      'video_guid': videoGuid,
      'event_type': eventType,
      'event_title': eventTitle,
      'voice_transcript': voiceTranscript,
      'voice_confidence': voiceConfidence,
      'drawing_url': drawingUrl,
      'drawing_data': drawingData,
      'notes': notes,
      'tags': tags,
    };
  }

  /// Formatea el timestamp del partido como texto legible (mm:ss)
  String get formattedTimestamp {
    final minutes = matchTimestamp ~/ 60;
    final seconds = matchTimestamp % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatea el timestamp del video (si existe) como texto legible (mm:ss)
  String get formattedVideoTimestamp {
    if (videoTimestamp == null) return '--:--';
    final minutes = videoTimestamp! ~/ 60;
    final seconds = videoTimestamp! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Indica si este evento fue creado en modo Live (sin video)
  bool get isLiveEvent => videoTimestamp == null;

  /// Indica si este evento ya está sincronizado con el video
  bool get isSynced => videoTimestamp != null;

  /// Copia con modificaciones
  AnalysisEvent copyWith({
    String? id,
    String? matchId,
    String? teamId,
    String? playerId,
    String? coachId,
    int? matchTimestamp,
    int? videoTimestamp,
    String? videoGuid,
    String? eventType,
    String? eventTitle,
    String? voiceTranscript,
    double? voiceConfidence,
    String? drawingUrl,
    Map<String, dynamic>? drawingData,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalysisEvent(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      coachId: coachId ?? this.coachId,
      matchTimestamp: matchTimestamp ?? this.matchTimestamp,
      videoTimestamp: videoTimestamp ?? this.videoTimestamp,
      videoGuid: videoGuid ?? this.videoGuid,
      eventType: eventType ?? this.eventType,
      eventTitle: eventTitle ?? this.eventTitle,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      voiceConfidence: voiceConfidence ?? this.voiceConfidence,
      drawingUrl: drawingUrl ?? this.drawingUrl,
      drawingData: drawingData ?? this.drawingData,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ============================================================
/// MODELO: EventType
/// ============================================================
/// Tipo de evento predefinido con metadata visual
/// ============================================================

class EventType {
  final String id;
  final String name;
  final String category; // 'offensive', 'defensive', 'neutral', 'error'
  final String? icon;
  final Color? color;
  final List<String>? keywords;

  EventType({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.color,
    this.keywords,
  });

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String?,
      color: json['color'] != null ? _parseColor(json['color'] as String) : null,
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'] as List)
          : null,
    );
  }

  /// Parsea un color hex a Color de Flutter
  static Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Obtiene el icono como IconData
  IconData? get iconData {
    if (icon == null) return null;
    // Mapeo simplificado de nombres de iconos Material
    final iconMap = {
      'sports_soccer': Icons.sports_soccer,
      'adjust': Icons.adjust,
      'swap_calls': Icons.swap_calls,
      'warning': Icons.warning,
      'sports_kabaddi': Icons.sports_kabaddi,
      'block': Icons.block,
      'flag': Icons.flag,
      'style': Icons.style,
      'cancel': Icons.cancel,
      'swap_horiz': Icons.swap_horiz,
      'local_hospital': Icons.local_hospital,
      'mic': Icons.mic,
      'edit': Icons.edit,
    };
    return iconMap[icon] ?? Icons.circle;
  }
}

/// ============================================================
/// RESULTADO DE VOICE TAGGING
/// ============================================================
/// Resultado del procesamiento de reconocimiento de voz
/// ============================================================

class VoiceTagResult {
  final String transcript;
  final double confidence;
  final String? detectedEventType;
  final String? detectedPlayerId;
  final String? detectedPlayerName;
  final List<String> suggestedTags;

  VoiceTagResult({
    required this.transcript,
    required this.confidence,
    this.detectedEventType,
    this.detectedPlayerId,
    this.detectedPlayerName,
    this.suggestedTags = const [],
  });

  bool get hasDetections =>
      detectedEventType != null || detectedPlayerId != null;

  @override
  String toString() {
    String result = 'Transcripción: "$transcript"';
    if (detectedEventType != null) {
      result += '\nEvento detectado: $detectedEventType';
    }
    if (detectedPlayerName != null) {
      result += '\nJugador detectado: $detectedPlayerName';
    }
    return result;
  }
}
