import 'package:myapp/models/drill_model.dart';

class TrainingSession {
  final String id;
  final DateTime date;
  final String title;
  final String objective;
  final List<Drill> drills;

  TrainingSession({
    required this.id,
    required this.date,
    required this.title,
    required this.objective,
    this.drills = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'objective': objective,
      'drills': drills.map((drill) => drill.toMap()).toList(),
    };
  }

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      id: map['id'],
      date: DateTime.parse(map['date']),
      title: map['title'],
      objective: map['objective'],
      drills: List<Drill>.from(map['drills']?.map((x) => Drill.fromMap(x)) ?? []),
    );
  }
}
