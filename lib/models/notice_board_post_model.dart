// ============================================================
// MODELO: NoticeBoardPost
// ============================================================
// Representa un comunicado oficial del tablón de anuncios
// ============================================================

enum NoticePriority {
  normal,
  urgent,
}

class NoticeBoardPost {
  final String id;
  final String? teamId; // NULL = para toda la escuela
  final String authorId;
  final String title;
  final String content; // Soporta markdown
  final String? attachmentUrl; // URL del PDF o imagen
  final NoticePriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Estadísticas (opcionales, se cargan por separado)
  final int? readCount;
  final int? totalUsers;

  NoticeBoardPost({
    required this.id,
    this.teamId,
    required this.authorId,
    required this.title,
    required this.content,
    this.attachmentUrl,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.readCount,
    this.totalUsers,
  });

  factory NoticeBoardPost.fromJson(Map<String, dynamic> json) {
    return NoticeBoardPost(
      id: json['id'] as String,
      teamId: json['team_id'] as String?,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      priority: _parsePriority(json['priority'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      readCount: json['read_count'] as int?,
      totalUsers: json['total_users'] as int?,
    );
  }

  static NoticePriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return NoticePriority.urgent;
      case 'normal':
      default:
        return NoticePriority.normal;
    }
  }

  String get priorityString {
    switch (priority) {
      case NoticePriority.urgent:
        return 'urgent';
      case NoticePriority.normal:
        return 'normal';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'author_id': authorId,
      'title': title,
      'content': content,
      'attachment_url': attachmentUrl,
      'priority': priorityString,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  NoticeBoardPost copyWith({
    String? id,
    String? teamId,
    String? authorId,
    String? title,
    String? content,
    String? attachmentUrl,
    NoticePriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? readCount,
    int? totalUsers,
  }) {
    return NoticeBoardPost(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readCount: readCount ?? this.readCount,
      totalUsers: totalUsers ?? this.totalUsers,
    );
  }
}
