import 'package:flutter/material.dart';
import 'package:myapp/data/drill_data.dart';
import 'package:myapp/models/drill_model.dart';

class DrillSelectionScreen extends StatefulWidget {
  const DrillSelectionScreen({super.key});

  @override
  State<DrillSelectionScreen> createState() => _DrillSelectionScreenState();
}

class _DrillSelectionScreenState extends State<DrillSelectionScreen> {
  final List<Drill> _selectedDrills = [];

  void _onDrillTapped(Drill drill) {
    setState(() {
      if (_selectedDrills.contains(drill)) {
        _selectedDrills.remove(drill);
      } else {
        _selectedDrills.add(drill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedDrills);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allDrills.length,
        itemBuilder: (context, index) {
          final drill = allDrills[index];
          final isSelected = _selectedDrills.contains(drill);
          return ListTile(
            title: Text(drill.title),
            subtitle: Text(drill.category),
            trailing: isSelected
                ? const Icon(Icons.check_box)
                : const Icon(Icons.check_box_outline_blank),
            onTap: () => _onDrillTapped(drill),
          );
        },
      ),
    );
  }
}
