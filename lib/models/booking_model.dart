class Booking {
  final String id;
  final String fieldId;
  final String teamId;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose; // 'training', 'match', 'tactical', 'other'
  final String title;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Información relacionada (opcional, para mostrar en UI)
  final String? fieldName;
  final String? teamName;

  Booking({
    required this.id,
    required this.fieldId,
    required this.teamId,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.title,
    this.description,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.fieldName,
    this.teamName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      teamId: json['team_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      purpose: json['purpose'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fieldName: json['fields']?['name'] as String?,
      teamName: json['teams']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'team_id': teamId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'purpose': purpose,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? fieldId,
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fieldName,
    String? teamName,
  }) {
    return Booking(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      teamId: teamId ?? this.teamId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fieldName: fieldName ?? this.fieldName,
      teamName: teamName ?? this.teamName,
    );
  }

  // Duración en minutos
  int get durationInMinutes => endTime.difference(startTime).inMinutes;

  // Formateador de hora para UI
  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  // Color según el propósito
  static String getPurposeColor(String purpose) {
    switch (purpose) {
      case 'training':
        return 'green';
      case 'match':
        return 'red';
      case 'tactical':
        return 'purple';
      default:
        return 'blue';
    }
  }

  // Label en español
  static String getPurposeLabel(String purpose) {
    switch (purpose) {
      case 'training':
        return 'Entrenamiento';
      case 'match':
        return 'Partido';
      case 'tactical':
        return 'Sesión Táctica';
      default:
        return 'Otro';
    }
  }
}
