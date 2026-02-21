import 'package:flutter/material.dart';
import 'package:myapp/data/player_data.dart';
import 'package:uuid/uuid.dart';

class TacticalTab extends StatefulWidget {
  const TacticalTab({super.key});

  @override
  State<TacticalTab> createState() => _TacticalTabState();
}

class _TacticalTabState extends State<TacticalTab> {
  final List<PlayerChip> _chips = [];
  String _selectedFormation = '4-3-3';

  @override
  void initState() {
    super.initState();
    _resetFormation();
  }

  void _resetFormation() {
    setState(() {
      _chips.clear();
      final formationPlayers = formations[_selectedFormation]!;
      for (int i = 0; i < formationPlayers.length; i++) {
        _chips.add(
          PlayerChip(
            id: const Uuid().v4(),
            pos: formationPlayers[i],
            label: teams[0].players[i].name.substring(0, 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizarra Táctica'),
        actions: [
          ElevatedButton(
            onPressed: _resetFormation,
            child: const Text('Reiniciar'),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _selectedFormation,
            items: formations.keys
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedFormation = v);
                _resetFormation();
              }
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Image.asset(
                'assets/field.png',
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.contain,
              ),
              ..._chips.map((chip) {
                return Positioned(
                  left: chip.pos.dx * constraints.maxWidth,
                  top: chip.pos.dy * constraints.maxHeight,
                  child: Draggable(
                    feedback: FloatingActionButton(
                      onPressed: () {},
                      mini: true,
                      child: Text(chip.label),
                    ),
                    child: FloatingActionButton(
                      onPressed: () {},
                      mini: true,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(chip.label),
                    ),
                    onDragEnd: (details) {
                      setState(() {
                        chip.pos = Offset(
                          details.offset.dx / constraints.maxWidth,
                          details.offset.dy / constraints.maxHeight,
                        );
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class PlayerChip {
  String id;
  String label;
  Offset pos;
  PlayerChip({required this.id, required this.label, required this.pos});
}

const Map<String, List<Offset>> formations = {
  '4-3-3': [
    Offset(0.45, 0.9), // GK
    Offset(0.2, 0.7),
    Offset(0.7, 0.7),
    Offset(0.3, 0.75),
    Offset(0.6, 0.75), // DEF
    Offset(0.3, 0.5), Offset(0.6, 0.5), Offset(0.45, 0.55), // MID
    Offset(0.2, 0.25), Offset(0.7, 0.25), Offset(0.45, 0.15), // FWD
  ],
  '4-4-2': [
    Offset(0.45, 0.9), // GK
    Offset(0.2, 0.7),
    Offset(0.7, 0.7),
    Offset(0.3, 0.75),
    Offset(0.6, 0.75), // DEF
    Offset(0.2, 0.5),
    Offset(0.7, 0.5),
    Offset(0.4, 0.5),
    Offset(0.5, 0.5), // MID
    Offset(0.3, 0.2), Offset(0.6, 0.2), // FWD
  ],
  '3-5-2': [
    Offset(0.45, 0.9), // GK
    Offset(0.2, 0.75), Offset(0.45, 0.78), Offset(0.7, 0.75), // DEF
    Offset(0.1, 0.5),
    Offset(0.8, 0.5),
    Offset(0.3, 0.5),
    Offset(0.6, 0.5),
    Offset(0.45, 0.4), // MID
    Offset(0.3, 0.2), Offset(0.6, 0.2), // FWD
  ],
};
