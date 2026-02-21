import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ============================================================
/// WIDGET: TelestrationLayer
/// ============================================================
/// Capa de dibujo transparente para marcar jugadas sobre video
/// Implementación nativa sin dependencias externas
/// ============================================================

class TelestrationLayer extends StatefulWidget {
  final TelestrationController controller;
  final bool isActive;
  final VoidCallback? onDrawingStarted;
  final VoidCallback? onDrawingEnded;

  const TelestrationLayer({
    super.key,
    required this.controller,
    this.isActive = true,
    this.onDrawingStarted,
    this.onDrawingEnded,
  });

  @override
  State<TelestrationLayer> createState() => _TelestrationLayerState();
}

class _TelestrationLayerState extends State<TelestrationLayer> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;

  @override
  void initState() {
    super.initState();
    widget.controller._bind(this, _repaintBoundaryKey);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: GestureDetector(
        onPanStart: (details) {
          widget.onDrawingStarted?.call();
          setState(() {
            _currentLine = DrawnLine(
              points: [details.localPosition],
              color: widget.controller._currentColor,
              strokeWidth: widget.controller._strokeWidth,
              isEraser:
                  widget.controller._currentTool == TelestrationTool.eraser,
            );
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _currentLine = _currentLine?.copyWith(
              points: [..._currentLine!.points, details.localPosition],
            );
          });
        },
        onPanEnd: (details) {
          widget.onDrawingEnded?.call();
          if (_currentLine != null) {
            setState(() {
              _lines.add(_currentLine!);
              _currentLine = null;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: CustomPaint(
            painter: TelestrationPainter(
              lines: [..._lines, if (_currentLine != null) _currentLine!],
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _lines.clear();
      _currentLine = null;
    });
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    }
  }
}

/// ============================================================
/// PAINTER: TelestrationPainter
/// ============================================================

class TelestrationPainter extends CustomPainter {
  final List<DrawnLine> lines;

  TelestrationPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (line.isEraser) {
        paint.blendMode = BlendMode.clear;
      }

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(TelestrationPainter oldDelegate) => true;
}

/// ============================================================
/// MODELO: DrawnLine
/// ============================================================

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  DrawnLine copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return DrawnLine(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}

/// ============================================================
/// CONTROLADOR EXTERNO
/// ============================================================

class TelestrationController {
  _TelestrationLayerState? _layerState;
  GlobalKey? _repaintKey;

  // Estado actual
  TelestrationTool _currentTool = TelestrationTool.pen;
  Color _currentColor = Colors.red;
  double _strokeWidth = 4.0;

  void _bind(_TelestrationLayerState state, GlobalKey repaintKey) {
    _layerState = state;
    _repaintKey = repaintKey;
  }

  void selectTool(TelestrationTool tool) {
    _currentTool = tool;
  }

  void setColor(Color color) {
    _currentColor = color;
    if (_currentTool == TelestrationTool.eraser) {
      _currentTool = TelestrationTool.pen;
    }
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
  }

  void clear() {
    _layerState?._clearAll();
  }

  void undo() {
    _layerState?._undo();
  }

  void redo() {
    // No implementado en esta versión simple
  }

  Future<Uint8List?> captureAsImage() async {
    try {
      final boundary =
          _repaintKey?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ No se pudo obtener RenderRepaintBoundary');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ No se pudo convertir la imagen a bytes');
        return null;
      }

      debugPrint('✅ Imagen capturada: ${byteData.lengthInBytes} bytes');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error capturando imagen: $e');
      return null;
    }
  }

  TelestrationTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;

  void dispose() {
    _layerState = null;
    _repaintKey = null;
  }
}

/// ============================================================
/// ENUM: TelestrationTool
/// ============================================================

enum TelestrationTool { pen, arrow, eraser }

/// ============================================================
/// WIDGET: TelestrationToolbar
/// ============================================================

class TelestrationToolbar extends StatelessWidget {
  final TelestrationController controller;
  final VoidCallback? onClear;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const TelestrationToolbar({
    super.key,
    required this.controller,
    this.onClear,
    this.onSave,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.cyan.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Herramientas principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.edit,
                label: 'Pincel',
                color: Colors.red,
                isSelected: controller.currentTool == TelestrationTool.pen,
                onTap: () => controller.selectTool(TelestrationTool.pen),
              ),
              _ToolButton(
                icon: Icons.arrow_forward,
                label: 'Flecha',
                color: Colors.yellow,
                isSelected: controller.currentTool == TelestrationTool.arrow,
                onTap: () => controller.selectTool(TelestrationTool.arrow),
              ),
              _ToolButton(
                icon: Icons.auto_fix_high,
                label: 'Borrador',
                color: Colors.grey,
                isSelected: controller.currentTool == TelestrationTool.eraser,
                onTap: () => controller.selectTool(TelestrationTool.eraser),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Paleta de colores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ColorButton(
                color: Colors.red,
                isSelected: controller.currentColor == Colors.red,
                onTap: () => controller.setColor(Colors.red),
              ),
              _ColorButton(
                color: Colors.yellow,
                isSelected: controller.currentColor == Colors.yellow,
                onTap: () => controller.setColor(Colors.yellow),
              ),
              _ColorButton(
                color: Colors.green,
                isSelected: controller.currentColor == Colors.green,
                onTap: () => controller.setColor(Colors.green),
              ),
              _ColorButton(
                color: Colors.blue,
                isSelected: controller.currentColor == Colors.blue,
                onTap: () => controller.setColor(Colors.blue),
              ),
              _ColorButton(
                color: Colors.white,
                isSelected: controller.currentColor == Colors.white,
                onTap: () => controller.setColor(Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.undo,
                label: 'Deshacer',
                onTap: () => controller.undo(),
              ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Limpiar',
                onTap: onClear,
              ),
              _ActionButton(
                icon: Icons.save,
                label: 'Guardar',
                color: Colors.cyan,
                onTap: onSave,
              ),
              _ActionButton(icon: Icons.close, label: 'Cerrar', onTap: onClose),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// WIDGETS AUXILIARES
/// ============================================================

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white70, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.cyan
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
