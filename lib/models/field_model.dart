class Field {
  final String id;
  final String name;
  final String type; // 'F7' o 'F11'
  final String? location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Field({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Field copyWith({
    String? id,
    String? name,
    String? type,
    String? location,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter para mostrar info completa
  String get displayName => '$name ($type)';
}
