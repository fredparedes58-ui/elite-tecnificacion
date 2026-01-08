
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/providers/tactic_board_provider.dart';
import 'package:myapp/widgets/drawing_painter.dart';
import 'package:myapp/widgets/pitch_view.dart';
import 'package:myapp/widgets/player_piece.dart';
import 'package:myapp/widgets/ball_piece.dart';
import 'package:provider/provider.dart';

class TacticalBoardScreen extends StatelessWidget {
  const TacticalBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TacticBoardProvider(),
      child: Consumer<TacticBoardProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Pizarra Táctica'),
              centerTitle: true,
              actions: _buildAppBarActions(context, provider),
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _buildBody(context, provider),
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, TacticBoardProvider provider) {
    return [
      if (provider.alignments.isNotEmpty) _buildAlignmentsDropdown(context, provider),
      if (provider.sessions.isNotEmpty) _buildSessionsDropdown(context, provider),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: provider.refreshPlayers,
        tooltip: 'Recargar Jugadores',
      ),
      IconButton(
        icon: const Icon(Icons.save),
        onPressed: () => _showSaveFormationDialog(context, provider),
        tooltip: 'Guardar Formación',
      ),
      IconButton(
        icon: const Icon(Icons.folder_open),
        onPressed: () => _showLoadFormationDialog(context, provider),
        tooltip: 'Cargar Formación',
      ),
      IconButton(
        icon: const Icon(Icons.save_as_outlined),
        onPressed: () => _showSaveSessionDialog(context, provider),
        tooltip: 'Guardar Jugada',
      ),
      IconButton(
        icon: Icon(
          provider.isDrawingMode ? Icons.edit_off_outlined : Icons.edit_outlined,
          color: provider.isDrawingMode ? Colors.amber : Colors.white,
        ),
        onPressed: provider.toggleDrawingMode,
        tooltip: 'Modo Dibujo',
      ),
      if (provider.lines.isNotEmpty || provider.currentLine.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: provider.clearDrawing,
          tooltip: 'Borrar Dibujos',
        ),
    ];
  }

  Widget _buildBody(BuildContext context, TacticBoardProvider provider) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return DragTarget<Object>(
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                     onPanStart: (details) {
                        if (provider.isDrawingMode) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          provider.onPanStart(box.globalToLocal(details.globalPosition));
                        }
                      },
                      onPanUpdate: (details) {
                        if (provider.isDrawingMode) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          provider.onPanUpdate(box.globalToLocal(details.globalPosition));
                        }
                      },
                      onPanEnd: (details) {
                        if (provider.isDrawingMode) provider.onPanEnd();
                      },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          const PitchView(),
                          CustomPaint(
                            painter: DrawingPainter(lines: provider.lines, currentLine: provider.currentLine),
                            size: Size.infinite,
                          ),
                          Positioned(
                            left: provider.ballPosition.dx,
                            top: provider.ballPosition.dy,
                            child: Draggable(
                              data: 'ball',
                              feedback: const BallPiece(),
                              childWhenDragging: Container(),
                              child: const BallPiece(),
                            ),
                          ),
                          ...provider.starters.map((player) {
                            final position = provider.starterPositions[player.name] ?? const Offset(100, 100);
                            final isSelected = provider.selectedPlayerForSubstitution?.name == player.name;
                            return Positioned(
                              left: position.dx,
                              top: position.dy,
                              child: GestureDetector(
                                onTap: () {
                                  if (provider.isSubstitutionMode && provider.selectedPlayerForSubstitution != null) {
                                    // Si ya hay un jugador seleccionado, hacer el cambio
                                    provider.substitutePlayer(player);
                                  } else {
                                    // Seleccionar este jugador para sustitución
                                    provider.selectPlayerForSubstitution(player);
                                  }
                                },
                                child: PlayerPiece(
                                  player: player,
                                  isSelected: isSelected,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                onAcceptWithDetails: (details) {
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.offset);
                  final adjustedPosition = Offset(localPosition.dx - 45, localPosition.dy - 100);

                  if (details.data is Player) {
                    final player = details.data as Player;
                    if (provider.starters.any((p) => p.name == player.name)) {
                      provider.updateStarterPosition(player, adjustedPosition);
                    } else {
                      provider.addStarter(player, adjustedPosition);
                    }
                  } else if (details.data == 'ball') {
                    provider.updateBallPosition(Offset(localPosition.dx - 14, localPosition.dy -14));
                  }
                },
              );
            },
          ),
        ),
        SubstitutesBench(substitutes: provider.substitutes),
      ],
    );
  }

  Widget _buildAlignmentsDropdown(BuildContext context, TacticBoardProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: provider.selectedAlignment?.id,
        items: provider.alignments.map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.name, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (id) => id != null ? provider.selectAlignment(id) : null,
        hint: const Text('Alineación', style: TextStyle(color: Colors.white70)),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Colors.grey[800],
      ),
    );
  }

  Widget _buildSessionsDropdown(BuildContext context, TacticBoardProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: provider.selectedSession?.id,
        items: provider.sessions.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (id) => id != null ? provider.loadTacticalSession(id) : null,
        hint: const Text('Jugadas', style: TextStyle(color: Colors.white70)),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Colors.grey[800],
      ),
    );
  }

  void _showSaveSessionDialog(BuildContext context, TacticBoardProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Jugada'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre de la jugada')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.saveTacticalSession(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSaveFormationDialog(BuildContext context, TacticBoardProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Formación'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre de la formación')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.saveFormation(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showLoadFormationDialog(BuildContext context, TacticBoardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cargar Formación'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.formations.length,
            itemBuilder: (context, index) {
              final formation = provider.formations[index];
              return ListTile(
                title: Text(formation.name),
                onTap: () {
                  provider.loadFormation(formation.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

class SubstitutesBench extends StatelessWidget {
  final List<Player> substitutes;
  const SubstitutesBench({super.key, required this.substitutes});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticBoardProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 160,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(77),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.airline_seat_recline_normal,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Banquillo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (provider.isSubstitutionMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'MODO SUSTITUCIÓN',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: provider.cancelSubstitution,
                              child: const Icon(Icons.close, color: Colors.amber, size: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: substitutes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay suplentes',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: substitutes.length,
                        itemBuilder: (context, index) {
                          final player = substitutes[index];
                          final isSelected = provider.selectedPlayerForSubstitution?.name == player.name;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                if (provider.isSubstitutionMode && provider.selectedPlayerForSubstitution != null) {
                                  // Si ya hay un jugador seleccionado, hacer el cambio
                                  provider.substitutePlayer(player);
                                } else {
                                  // Seleccionar este jugador para sustitución
                                  provider.selectPlayerForSubstitution(player);
                                }
                              },
                              child: PlayerPiece(
                                player: player,
                                isSelected: isSelected,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
