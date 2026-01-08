
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/providers/tactic_board_provider.dart';
import 'package:myapp/widgets/drawing_painter.dart';
import 'package:myapp/widgets/pitch_view.dart';
import 'package:myapp/widgets/player_piece.dart';
import 'package:myapp/widgets/ball_piece.dart';
import 'package:myapp/widgets/snap_grid_painter.dart';
import 'package:myapp/screens/alignment_editor_screen.dart';
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
      // Botón para crear nueva alineación
      IconButton(
        icon: const Icon(Icons.add_box_outlined),
        onPressed: () => _showCreateAlignmentDialog(context, provider),
        tooltip: 'Nueva Alineación',
      ),
      // Dropdown de alineaciones con botón de editar
      if (provider.alignments.isNotEmpty) _buildAlignmentsDropdown(context, provider),
      if (provider.sessions.isNotEmpty) _buildSessionsDropdown(context, provider),
      IconButton(
        icon: Icon(
          provider.enableSnapping ? Icons.grid_on : Icons.grid_off,
          color: provider.enableSnapping ? Colors.greenAccent : Colors.white54,
        ),
        onPressed: provider.toggleSnapping,
        tooltip: provider.enableSnapping ? 'Snap Activado' : 'Snap Desactivado',
      ),
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
              final pitchWidth = constraints.maxWidth - 32; // Restar padding
              final pitchHeight = constraints.maxHeight;
              
              return DragTarget<Object>(
                builder: (context, candidateData, rejectedData) {
                  final isDraggingPlayer = candidateData.isNotEmpty && candidateData.first is Player;
                  
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
                          
                          // Grid de snapping (puntos magnéticos) cuando está habilitado
                          if (provider.enableSnapping)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: SnapGridPainter(showGrid: true),
                              ),
                            ),
                          
                          // Indicadores de zona cuando se arrastra un jugador
                          if (isDraggingPlayer)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: ZoneIndicatorPainter(),
                              ),
                            ),
                          
                          CustomPaint(
                            painter: DrawingPainter(lines: provider.lines, currentLine: provider.currentLine),
                            size: Size.infinite,
                          ),
                          
                          // Balón
                          Positioned(
                            left: provider.ballPosition.dx,
                            top: provider.ballPosition.dy,
                            child: Draggable(
                              data: 'ball',
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: const BallPiece(),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: const BallPiece(),
                              ),
                              child: const BallPiece(),
                            ),
                          ),
                          
                          // Jugadores titulares
                          ...provider.starters.map((player) {
                            final position = provider.starterPositions[player.name] ?? const Offset(100, 100);
                            final isSelected = provider.selectedPlayerForSubstitution?.name == player.name;
                            return Positioned(
                              left: position.dx,
                              top: position.dy,
                              child: GestureDetector(
                                onTap: () {
                                  if (provider.isSubstitutionMode && provider.selectedPlayerForSubstitution != null) {
                                    provider.substitutePlayer(player);
                                  } else {
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
                  
                  if (details.data is Player) {
                    final player = details.data as Player;
                    
                    // IGUAL QUE LA BOLA: Centrar usando la mitad del tamaño del avatar
                    const playerSize = 60.0;
                    const halfSize = playerSize / 2; // 30px
                    
                    // SIN LÍMITES - Posicionar exactamente donde se suelta (igual que la bola)
                    final adjustedPosition = Offset(
                      localPosition.dx - halfSize, // Centro horizontal del avatar
                      localPosition.dy - halfSize, // Centro vertical del avatar
                    );

                    if (provider.starters.any((p) => p.name == player.name)) {
                      provider.updateStarterPosition(player, adjustedPosition);
                    } else {
                      provider.addStarter(player, adjustedPosition);
                    }
                    HapticFeedback.lightImpact(); // Feedback al soltar
                    
                  } else if (details.data == 'ball') {
                    // BOLA: Usar la mitad del tamaño (28px / 2 = 14px)
                    provider.updateBallPosition(Offset(localPosition.dx - 14, localPosition.dy - 14));
                  }
                },
                onWillAcceptWithDetails: (details) {
                  // Retornar true para indicar que el área acepta el drop
                  return true;
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: provider.selectedAlignment?.id,
            items: provider.alignments.map((a) => DropdownMenuItem<String>(
              value: a.id, 
              child: Row(
                children: [
                  Text(a.name, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  if (a.isCustom)
                    Icon(Icons.edit, size: 14, color: Colors.amber.withOpacity(0.7)),
                ],
              ),
            )).toList(),
            onChanged: (id) => id != null ? provider.selectAlignment(id) : null,
            hint: const Text('Alineación', style: TextStyle(color: Colors.white70)),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.grey[800],
          ),
        ),
        // Botón de editar si la alineación seleccionada es personalizada
        if (provider.selectedAlignment != null && provider.selectedAlignment!.isCustom)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.amber),
            onPressed: () => _navigateToAlignmentEditor(context, provider, provider.selectedAlignment),
            tooltip: 'Editar Alineación',
          ),
      ],
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

  // ============================================================
  // MÉTODOS PARA ALINEACIONES PERSONALIZADAS
  // ============================================================

  /// Mostrar diálogo para crear nueva alineación
  void _showCreateAlignmentDialog(BuildContext context, TacticBoardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nueva Alineación',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Qué deseas hacer?'),
            const SizedBox(height: 16),
            
            // Opción 1: Crear desde configuración actual
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text('Guardar configuración actual'),
              subtitle: const Text('Guardar jugadores tal como están en el campo'),
              onTap: () {
                Navigator.pop(context);
                _showSaveCurrentSetupDialog(context, provider);
              },
            ),
            
            const Divider(),
            
            // Opción 2: Crear nueva desde cero
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.blue),
              title: const Text('Crear desde cero'),
              subtitle: const Text('Asignar jugadores a posiciones manualmente'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAlignmentEditor(context, provider, null);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para guardar la configuración actual como alineación
  void _showSaveCurrentSetupDialog(BuildContext context, TacticBoardProvider provider) {
    final nameController = TextEditingController();
    final formationController = TextEditingController(text: '4-4-2');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Guardar Alineación Actual',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre de la alineación',
                hintText: 'Ej: Alineación vs Madrid',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: formationController,
              decoration: const InputDecoration(
                labelText: 'Formación',
                hintText: '4-4-2, 4-3-3, 3-5-2, etc.',
                prefixIcon: Icon(Icons.grid_4x4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final alignment = provider.createAlignmentFromCurrentSetup(
                  nameController.text,
                  formationController.text.isNotEmpty ? formationController.text : '4-4-2',
                );
                
                final success = await provider.saveAlignment(alignment);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Alineación guardada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  /// Navegar a la pantalla de edición de alineación
  Future<void> _navigateToAlignmentEditor(
    BuildContext context,
    TacticBoardProvider provider,
    dynamic alignment,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlignmentEditorScreen(
          alignment: alignment,
          availablePlayers: provider.allPlayers.where((p) => p.id != null).toList(),
        ),
      ),
    );

    if (result != null && result is alignment_model.Alignment) {
      final success = await provider.saveAlignment(result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alineación guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// ============================================================
// PAINTER: Indicadores de Zona durante Arrastre
// ============================================================
class ZoneIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final height = size.height;
    final zoneHeight = height / 3;

    // Zona de ATAQUE (superior) - Rojo suave
    paint.color = Colors.red.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, zoneHeight),
      paint,
    );

    // Línea divisoria
    paint
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, zoneHeight),
      Offset(size.width, zoneHeight),
      paint,
    );

    // Zona de MEDIO CAMPO - Amarillo suave
    paint
      ..color = Colors.amber.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, zoneHeight, size.width, zoneHeight),
      paint,
    );

    // Línea divisoria
    paint
      ..color = Colors.amber.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, zoneHeight * 2),
      Offset(size.width, zoneHeight * 2),
      paint,
    );

    // Zona de DEFENSA (inferior) - Azul suave
    paint
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, zoneHeight * 2, size.width, zoneHeight),
      paint,
    );

    // Etiquetas de zona
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Label ATAQUE
    textPainter.text = TextSpan(
      text: 'ATAQUE',
      style: TextStyle(
        color: Colors.red.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 20));

    // Label MEDIO CAMPO
    textPainter.text = TextSpan(
      text: 'MEDIO CAMPO',
      style: TextStyle(
        color: Colors.amber.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, zoneHeight + 20));

    // Label DEFENSA
    textPainter.text = TextSpan(
      text: 'DEFENSA',
      style: TextStyle(
        color: Colors.blue.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, zoneHeight * 2 + 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
