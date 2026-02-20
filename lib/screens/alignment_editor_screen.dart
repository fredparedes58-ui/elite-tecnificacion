import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/models/player_model.dart';
import 'package:myapp/widgets/pitch_view.dart';
import 'package:myapp/widgets/player_piece.dart';

/// Pantalla para crear/editar alineaciones con asignación de jugadores
class AlignmentEditorScreen extends StatefulWidget {
  final alignment_model.Alignment? alignment; // null = crear nueva, no-null = editar
  final List<Player> availablePlayers;

  const AlignmentEditorScreen({
    super.key,
    this.alignment,
    required this.availablePlayers,
  });

  @override
  State<AlignmentEditorScreen> createState() => _AlignmentEditorScreenState();
}

class _AlignmentEditorScreenState extends State<AlignmentEditorScreen> {
  late TextEditingController _nameController;
  late String _selectedFormation;
  late Map<String, alignment_model.PlayerPosition> _playerPositions;
  
  // Formaciones predefinidas con posiciones
  final Map<String, List<Offset>> _formationPositions = {
    '4-4-2': [
      const Offset(180, 600),  // Portero
      const Offset(80, 480),   // Defensa 1
      const Offset(140, 500),  // Defensa 2
      const Offset(220, 500),  // Defensa 3
      const Offset(280, 480),  // Defensa 4
      const Offset(80, 340),   // Medio 1
      const Offset(140, 360),  // Medio 2
      const Offset(220, 360),  // Medio 3
      const Offset(280, 340),  // Medio 4
      const Offset(140, 180),  // Delantero 1
      const Offset(220, 180),  // Delantero 2
    ],
    '4-3-3': [
      const Offset(180, 600),  // Portero
      const Offset(80, 480),   // Defensa 1
      const Offset(140, 500),  // Defensa 2
      const Offset(220, 500),  // Defensa 3
      const Offset(280, 480),  // Defensa 4
      const Offset(100, 340),  // Medio 1
      const Offset(180, 360),  // Medio 2
      const Offset(260, 340),  // Medio 3
      const Offset(80, 180),   // Delantero 1
      const Offset(180, 160),  // Delantero 2
      const Offset(280, 180),  // Delantero 3
    ],
    '3-5-2': [
      const Offset(180, 600),  // Portero
      const Offset(100, 500),  // Defensa 1
      const Offset(180, 520),  // Defensa 2
      const Offset(260, 500),  // Defensa 3
      const Offset(80, 340),   // Medio 1
      const Offset(120, 360),  // Medio 2
      const Offset(180, 360),  // Medio 3
      const Offset(240, 360),  // Medio 4
      const Offset(280, 340),  // Medio 5
      const Offset(140, 180),  // Delantero 1
      const Offset(220, 180),  // Delantero 2
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.alignment?.name ?? '');
    _selectedFormation = widget.alignment?.formation ?? '4-4-2';
    _playerPositions = Map.from(widget.alignment?.playerPositions ?? {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Obtener jugador asignado a una posición
  Player? _getPlayerAtPosition(int positionIndex) {
    for (var entry in _playerPositions.entries) {
      final player = widget.availablePlayers.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Player(name: '', isStarter: false, image: ''),
      );
      
      if (player.name.isNotEmpty) {
        final positions = _formationPositions[_selectedFormation]!;
        final assignedPosition = positions.indexOf(entry.value.offset);
        if (assignedPosition == positionIndex) {
          return player;
        }
      }
    }
    return null;
  }

  // Asignar jugador a posición
  void _assignPlayerToPosition(int positionIndex) {
    final positions = _formationPositions[_selectedFormation]!;
    final position = positions[positionIndex];

    showDialog(
      context: context,
      builder: (context) => _PlayerSelectorDialog(
        availablePlayers: widget.availablePlayers,
        onPlayerSelected: (player) {
          setState(() {
            // Remover jugador de posición anterior si ya está asignado
            _playerPositions.removeWhere((key, value) => key == player.id);
            
            // Asignar jugador a nueva posición
            _playerPositions[player.id!] = alignment_model.PlayerPosition(
              offset: position,
              role: _getRoleForPosition(positionIndex),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Obtener rol según índice de posición
  String _getRoleForPosition(int index) {
    if (index == 0) return 'Portero';
    if (_selectedFormation == '4-4-2') {
      if (index <= 4) return 'Defensa';
      if (index <= 8) return 'Medio';
      return 'Delantero';
    }
    if (_selectedFormation == '4-3-3') {
      if (index <= 4) return 'Defensa';
      if (index <= 7) return 'Medio';
      return 'Delantero';
    }
    if (_selectedFormation == '3-5-2') {
      if (index <= 3) return 'Defensa';
      if (index <= 8) return 'Medio';
      return 'Delantero';
    }
    return 'Jugador';
  }

  void _saveAlignment() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }

    if (_playerPositions.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes asignar los 11 jugadores')),
      );
      return;
    }

    final newAlignment = alignment_model.Alignment(
      id: widget.alignment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      formation: _selectedFormation,
      playerPositions: _playerPositions,
      createdAt: widget.alignment?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isCustom: true,
    );

    Navigator.pop(context, newAlignment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positions = _formationPositions[_selectedFormation]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alignment == null ? 'Nueva Alineación' : 'Editar Alineación',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAlignment,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de la alineación
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la alineación',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Selector de formación
            Text(
              'Formación',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '4-4-2', label: Text('4-4-2')),
                ButtonSegment(value: '4-3-3', label: Text('4-3-3')),
                ButtonSegment(value: '3-5-2', label: Text('3-5-2')),
              ],
              selected: {_selectedFormation},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFormation = newSelection.first;
                  _playerPositions.clear(); // Limpiar asignaciones al cambiar formación
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Contador
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Jugadores asignados: ${_playerPositions.length}/11',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _playerPositions.length == 11 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Campo con posiciones
            Text(
              'Toca cada posición para asignar un jugador',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            
            AspectRatio(
              aspectRatio: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Campo
                      const PitchView(),
                      
                      // Posiciones con jugadores asignados
                      ...List.generate(positions.length, (index) {
                        final position = positions[index];
                        final assignedPlayer = _getPlayerAtPosition(index);
                        
                        return Positioned(
                          left: position.dx,
                          top: position.dy,
                          child: GestureDetector(
                            onTap: () => _assignPlayerToPosition(index),
                            child: assignedPlayer != null
                                ? PlayerPiece(player: assignedPlayer)
                                : _EmptyPositionMarker(
                                    role: _getRoleForPosition(index),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botón de guardar (inferior)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveAlignment,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR ALINEACIÓN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador de posición vacía
class _EmptyPositionMarker extends StatelessWidget {
  final String role;
  
  const _EmptyPositionMarker({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white70,
        size: 32,
      ),
    );
  }
}

/// Diálogo para seleccionar jugador
class _PlayerSelectorDialog extends StatelessWidget {
  final List<Player> availablePlayers;
  final Function(Player) onPlayerSelected;

  const _PlayerSelectorDialog({
    required this.availablePlayers,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Seleccionar Jugador',
        style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: player.image.startsWith('http')
                    ? NetworkImage(player.image)
                    : AssetImage(player.image) as ImageProvider,
              ),
              title: Text(player.name),
              subtitle: Text(player.role ?? 'Jugador'),
              onTap: () => onPlayerSelected(player),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }
}
