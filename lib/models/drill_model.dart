class Drill {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final List<String> objectives;

  Drill({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.objectives = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'objectives': objectives,
    };
  }

  factory Drill.fromMap(Map<String, dynamic> map) {
    return Drill(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      difficulty: map['difficulty'],
      objectives: List<String>.from(map['objectives'] ?? []),
    );
  }
}
