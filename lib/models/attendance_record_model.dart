// ============================================================
// MODELO: AttendanceRecord
// ============================================================
// Representa el registro de asistencia de un jugador a una sesión
// ============================================================

enum AttendanceStatus {
  present, // Presente
  absent, // Ausente
  late, // Tarde
  injured, // Lesionado
  sick, // Enfermo
}

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String playerId;
  final AttendanceStatus status;
  final String? note;
  final String? markedBy; // ID del usuario que marcó la asistencia (coach, parent, o player)
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.status,
    this.note,
    this.markedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      playerId: json['player_id'] as String,
      status: _parseStatus(json['status'] as String),
      note: json['note'] as String?,
      markedBy: json['marked_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static AttendanceStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'injured':
        return AttendanceStatus.injured;
      case 'sick':
        return AttendanceStatus.sick;
      default:
        return AttendanceStatus.present;
    }
  }

  String get statusString {
    switch (status) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.injured:
        return 'injured';
      case AttendanceStatus.sick:
        return 'sick';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'player_id': playerId,
      'status': statusString,
      'note': note,
      'marked_by': markedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? playerId,
    AttendanceStatus? status,
    String? note,
    String? markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      status: status ?? this.status,
      note: note ?? this.note,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
