class BookingRequest {
  final String id;
  final String requesterId;
  final String? requesterName;
  final String desiredFieldId;
  final DateTime desiredStartTime;
  final DateTime desiredEndTime;
  final String purpose; // 'training', 'match', 'tactical', 'other'
  final String title;
  final String? reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Información relacionada (para UI)
  final String? fieldName;

  BookingRequest({
    required this.id,
    required this.requesterId,
    this.requesterName,
    required this.desiredFieldId,
    required this.desiredStartTime,
    required this.desiredEndTime,
    required this.purpose,
    required this.title,
    this.reason,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
    this.fieldName,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterName: json['requester_name'] as String?,
      desiredFieldId: json['desired_field_id'] as String,
      desiredStartTime: DateTime.parse(json['desired_start_time'] as String),
      desiredEndTime: DateTime.parse(json['desired_end_time'] as String),
      purpose: json['purpose'] as String,
      title: json['title'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewNotes: json['review_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fieldName: json['fields']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'desired_field_id': desiredFieldId,
      'desired_start_time': desiredStartTime.toIso8601String(),
      'desired_end_time': desiredEndTime.toIso8601String(),
      'purpose': purpose,
      'title': title,
      'reason': reason,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BookingRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? desiredFieldId,
    DateTime? desiredStartTime,
    DateTime? desiredEndTime,
    String? purpose,
    String? title,
    String? reason,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fieldName,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      desiredFieldId: desiredFieldId ?? this.desiredFieldId,
      desiredStartTime: desiredStartTime ?? this.desiredStartTime,
      desiredEndTime: desiredEndTime ?? this.desiredEndTime,
      purpose: purpose ?? this.purpose,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fieldName: fieldName ?? this.fieldName,
    );
  }

  // Getters útiles
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get timeRange {
    final start = '${desiredStartTime.hour.toString().padLeft(2, '0')}:${desiredStartTime.minute.toString().padLeft(2, '0')}';
    final end = '${desiredEndTime.hour.toString().padLeft(2, '0')}:${desiredEndTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }
}
