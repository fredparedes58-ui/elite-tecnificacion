
import 'package:flutter/material.dart';
import 'package:myapp/data/drill_data.dart';
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/widgets/drill_card.dart';

class DrillsScreen extends StatefulWidget {
  const DrillsScreen({super.key});

  @override
  State<DrillsScreen> createState() => _DrillsScreenState();
}

class _DrillsScreenState extends State<DrillsScreen> {
  final List<Drill> _drills = allDrills;
  late List<Drill> _filteredDrills;
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  List<String> get _categories => ['All', ..._drills.map((d) => d.category).toSet()];
  List<String> get _difficulties => ['All', 'Baja', 'Media', 'Alta'];

  void _applyFilters() {
    setState(() {
      Iterable<Drill> tempDrills = _drills;

      if (_selectedCategory != 'All') {
        tempDrills = tempDrills.where((d) => d.category == _selectedCategory);
      }

      if (_selectedDifficulty != 'All') {
        tempDrills = tempDrills.where((d) => d.difficulty == _selectedDifficulty);
      }

      _filteredDrills = tempDrills.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(
            label: "Categoría",
            items: _categories,
            selectedItem: _selectedCategory,
            onSelected: (category) {
              _selectedCategory = category;
              _applyFilters();
            },
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildFilterSection(
            label: "Dificultad",
            items: _difficulties,
            selectedItem: _selectedDifficulty,
            onSelected: (difficulty) {
              _selectedDifficulty = difficulty;
              _applyFilters();
            },
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredDrills.length,
              itemBuilder: (context, index) {
                return DrillCard(drill: _filteredDrills[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String label,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selectedItem;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onSelected(item);
                    }
                  },
                  labelStyle: textTheme.labelLarge?.copyWith(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(128),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  elevation: isSelected ? 4 : 0,
                  pressElevation: 8,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
