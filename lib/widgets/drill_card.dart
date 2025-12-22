
import 'package:flutter/material.dart';
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/screens/drill_details_screen.dart';

class DrillCard extends StatelessWidget {
  final Drill drill;

  const DrillCard({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
       onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrillDetailsScreen(drill: drill),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: colorScheme.primary.withAlpha(100), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                colorScheme.surface, 
                colorScheme.surface.withAlpha(230), 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(60),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'drill-image-${drill.id}',
                child: _buildDrillImage(context, colorScheme),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.title,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(Icons.category_outlined, drill.category, colorScheme.secondary, textTheme, context),
                        const SizedBox(width: 10),
                        _buildInfoChip(Icons.moving_sharp, drill.difficulty, colorScheme.primary, textTheme, context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrillImage(BuildContext context, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        // child: Image.network( 
        //   drill.image,
        //   fit: BoxFit.cover,
        //   frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        //     if (wasSynchronouslyLoaded) return child;
        //     return AnimatedOpacity(
        //       opacity: frame == null ? 0 : 1,
        //       duration: const Duration(seconds: 1),
        //       curve: Curves.easeOut,
        //       child: child,
        //     );
        //   },
        //   errorBuilder: (context, error, stackTrace) {
        //     return Container(
        //       color: colorScheme.surface,
        //       child: const Icon(Icons.sports_soccer, size: 50, color: Colors.white24),
        //     );
        //   },
        // ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, TextTheme textTheme, BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color.withAlpha(200)),
      label: Text(label),
      backgroundColor: color.withAlpha(38),
      labelStyle: textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withAlpha(77)),
      ),
    );
  }
}
