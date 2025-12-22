
enum DrillIntensity { alta, media, baja }

class Drill {
  final String title;
  final String description;
  final String category;
  final DrillIntensity intensity;
  final String players;
  final String time;
  final String imagePath;

  Drill({
    required this.title,
    required this.description,
    required this.category,
    required this.intensity,
    required this.players,
    required this.time,
    required this.imagePath,
  });
}
