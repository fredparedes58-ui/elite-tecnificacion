// ============================================================
// MODELO: NoticeReadReceipt
// ============================================================
// Representa el acuse de recibo de lectura de un comunicado
// ============================================================

class NoticeReadReceipt {
  final String id;
  final String noticeId;
  final String userId;
  final DateTime readAt;

  NoticeReadReceipt({
    required this.id,
    required this.noticeId,
    required this.userId,
    required this.readAt,
  });

  factory NoticeReadReceipt.fromJson(Map<String, dynamic> json) {
    return NoticeReadReceipt(
      id: json['id'] as String,
      noticeId: json['notice_id'] as String,
      userId: json['user_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notice_id': noticeId,
      'user_id': userId,
      'read_at': readAt.toIso8601String(),
    };
  }
}
