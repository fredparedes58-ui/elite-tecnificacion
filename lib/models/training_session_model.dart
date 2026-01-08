// ============================================================
// MODELO: TrainingSession
// ============================================================
// Representa una sesión de entrenamiento del equipo
// ============================================================

class TrainingSession {
  final String id;
  final String teamId;
  final DateTime date;
  final String? topic;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingSession({
    required this.id,
    required this.teamId,
    required this.date,
    this.topic,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      date: DateTime.parse(json['date'] as String),
      topic: json['topic'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'date': date.toIso8601String(),
      'topic': topic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TrainingSession copyWith({
    String? id,
    String? teamId,
    DateTime? date,
    String? topic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      date: date ?? this.date,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
