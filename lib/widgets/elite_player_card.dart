import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/player_stats.dart';
import 'package:myapp/utils/category_colors.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:myapp/widgets/terms_of_image_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Claves FIFA para el radar de 6 puntas
const List<String> kFifaSkillKeys = ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];

/// Convierte [PlayerStats] al mapa de 6 habilidades FIFA (0-100).
/// Usa [stats.skills] si tiene las claves FIFA; si no, deriva de velocidad/tecnica/fisico/mental/tactico.
Map<String, double> fifaSkillsFromPlayerStats(PlayerStats stats) {
  final map = <String, double>{};
  final raw = stats.skills;
  for (final key in kFifaSkillKeys) {
    if (raw.containsKey(key) && raw[key] != null) {
      map[key] = (raw[key]!).clamp(0.0, 100.0);
    } else {
      map[key] = 0.0;
    }
  }
  if (map.values.every((v) => v == 0.0) &&
      (stats.velocidad > 0 || stats.tecnica > 0 || stats.fisico > 0 || stats.mental > 0 || stats.tactico > 0)) {
    map['PAC'] = stats.velocidad.clamp(0.0, 100.0);
    map['SHO'] = (stats.tecnica * 0.5 + stats.fisico * 0.5).clamp(0.0, 100.0);
    map['PAS'] = stats.tecnica.clamp(0.0, 100.0);
    map['DRI'] = stats.tecnica.clamp(0.0, 100.0);
    map['DEF'] = stats.tactico.clamp(0.0, 100.0);
    map['PHY'] = stats.fisico.clamp(0.0, 100.0);
  }
  return map;
}

/// Carta estilo EA Sports FC (FIFA) Ultimate Team.
/// - Fondo dark, borde neón #39FF14.
/// - Foto del jugador subible desde el área de ficha por padres o coach.
/// - Nombre, posición, categoría (con color por categoría) y radar de 6 puntas (PAC, SHO, PAS, DRI, DEF, PHY).
/// - Total Value (media) en esquina superior derecha, recalculado en tiempo real al editar skills.
/// - Notas editables solo si [isCoach] es true.
class ElitePlayerCard extends StatefulWidget {
  final Player player;
  final String? category;
  final String? playerId;
  final bool isCoach;
  final bool canEditPhoto;
  final String? initialNotes;
  final VoidCallback? onPhotoUpdated;
  final void Function(Map<String, double> skills)? onSkillsSaved;
  final void Function(String notes)? onNotesSaved;

  const ElitePlayerCard({
    super.key,
    required this.player,
    this.category,
    this.playerId,
    this.isCoach = false,
    this.canEditPhoto = false,
    this.initialNotes,
    this.onPhotoUpdated,
    this.onSkillsSaved,
    this.onNotesSaved,
  });

  @override
  State<ElitePlayerCard> createState() => _ElitePlayerCardState();
}

class _ElitePlayerCardState extends State<ElitePlayerCard> {
  late Map<String, double> _skills;
  late TextEditingController _notesController;
  String? _notes;
  bool _isSavingNotes = false;
  bool _isUploadingPhoto = false;
  String? _currentPhotoUrl;
  final FileManagementService _fileService = FileManagementService();

  static const Color _neonGreen = Color(0xFF39FF14);
  static const Color _darkBg = Color(0xFF0D1117);

  @override
  void initState() {
    super.initState();
    _skills = Map.from(fifaSkillsFromPlayerStats(widget.player.stats));
    _notes = widget.initialNotes;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _currentPhotoUrl = widget.player.image;
  }

  @override
  void didUpdateWidget(covariant ElitePlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _skills = Map.from(fifaSkillsFromPlayerStats(widget.player.stats));
      _currentPhotoUrl = widget.player.image;
    }
    if (oldWidget.initialNotes != widget.initialNotes && widget.initialNotes != null) {
      _notes = widget.initialNotes;
      _notesController.text = widget.initialNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalValue {
    if (_skills.isEmpty) return 0;
    final sum = _skills.values.fold<double>(0, (a, b) => a + b);
    return (sum / _skills.length).roundToDouble();
  }

  Future<void> _showImageSourceDialog() async {
    if (!widget.canEditPhoto || widget.playerId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _darkBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: _neonGreen.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _neonGreen),
              title: const Text('Tomar foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _neonGreen),
              title: const Text('Galería', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageFromGallery();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.folder_open, color: _neonGreen),
                title: const Text('Archivos', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!await _ensureImageTermsAccepted()) return;
                  final file = await _fileService.pickFile(type: FileType.image);
                  if (file != null) await _uploadImage(File(file.path));
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensureImageTermsAccepted() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return true;
    if (await hasAcceptedImageTerms(userId)) return true;
    if (!mounted) return false;
    final accepted = await showTermsOfImageModal(context);
    if (accepted) await setImageTermsAccepted(userId);
    return accepted;
  }

  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) return;
    if (!await _ensureImageTermsAccepted()) return;
    final image = await _fileService.pickImageFromCamera();
    if (image != null) await _uploadImage(image);
  }

  Future<void> _pickImageFromGallery() async {
    if (!await _ensureImageTermsAccepted()) return;
    final image = await _fileService.pickImageFromGallery();
    if (image != null) await _uploadImage(image);
  }

  Future<void> _uploadImage(File file) async {
    if (widget.playerId == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _fileService.uploadImage(
        image: file,
        folder: 'player-photos',
        imageName: 'player_${widget.playerId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url == null) {
        _showSnack('Error al subir la imagen', isError: true);
        setState(() => _isUploadingPhoto = false);
        return;
      }
      await Supabase.instance.client.from('profiles').update({'avatar_url': url}).eq('id', widget.playerId!);
      setState(() {
        _currentPhotoUrl = url;
        _isUploadingPhoto = false;
      });
      _showSnack('Foto actualizada');
      widget.onPhotoUpdated?.call();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : _neonGreen.withValues(alpha: 0.8)),
    );
  }

  void _onSkillChanged(String key, double value) {
    setState(() {
      _skills[key] = value.clamp(0.0, 100.0);
    });
    widget.onSkillsSaved?.call(Map.from(_skills));
  }

  void _saveNotes() async {
    final text = _notesController.text.trim();
    setState(() => _isSavingNotes = true);
    widget.onNotesSaved?.call(text);
    setState(() {
      _notes = text;
      _isSavingNotes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.forCategory(widget.category);

    return Container(
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _neonGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: _neonGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: Total Value (esquina derecha) + badge categoría (izquierda)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.category != null && widget.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: categoryColor, width: 1),
                      ),
                      child: Text(
                        widget.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _neonGreen, width: 1.5),
                    ),
                    child: Text(
                      '${_totalValue.toInt()}',
                      style: const TextStyle(
                        color: _neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Foto + nombre + posición
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.canEditPhoto && !_isUploadingPhoto ? _showImageSourceDialog : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _neonGreen, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _neonGreen.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildAvatarImage(),
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                              child: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _neonGreen))),
                            ),
                          ),
                        if (widget.canEditPhoto && !_isUploadingPhoto)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: _neonGreen, shape: BoxShape.circle, border: Border.all(color: _darkBg, width: 1)),
                              child: const Icon(Icons.camera_alt, size: 16, color: _darkBg),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.player.role ?? '—',
                          style: TextStyle(
                            color: _neonGreen.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Radar 6 puntas
              SizedBox(
                height: 200,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        dataEntries: kFifaSkillKeys.map((k) => RadarEntry(value: (_skills[k] ?? 0).clamp(0.0, 100.0))).toList(),
                        borderColor: _neonGreen,
                        fillColor: _neonGreen.withValues(alpha: 0.15),
                        borderWidth: 2,
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData: BorderSide(color: _neonGreen.withValues(alpha: 0.4)),
                    tickBorderData: BorderSide(color: _neonGreen.withValues(alpha: 0.25)),
                    ticksTextStyle: TextStyle(color: _neonGreen.withValues(alpha: 0.7), fontSize: 10),
                    tickCount: 5,
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                        text: kFifaSkillKeys[index],
                        angle: angle,
                      );
                    },
                    titleTextStyle: TextStyle(
                      color: _neonGreen.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    titlePositionPercentageOffset: 0.2,
                  ),
                ),
              ),
              // Sliders para editar skills (solo coach) — recálculo en tiempo real vía setState
              if (widget.isCoach) ...[
                const SizedBox(height: 8),
                ...kFifaSkillKeys.map((key) {
                  final v = (_skills[key] ?? 0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(key, style: const TextStyle(color: _neonGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _neonGreen,
                              inactiveTrackColor: _neonGreen.withValues(alpha: 0.2),
                              thumbColor: _neonGreen,
                            ),
                            child: Slider(
                              value: v,
                              min: 0,
                              max: 100,
                              onChanged: (val) => _onSkillChanged(key, val),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text('${v.round()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              // Notas (solo editables por coach)
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.notes, color: _neonGreen, size: 18),
                  const SizedBox(width: 8),
                  const Text('Notas', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              widget.isCoach
                  ? TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Notas del entrenador...',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _neonGreen.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _neonGreen.withValues(alpha: 0.3)),
                        ),
                      ),
                      onSubmitted: (_) => _saveNotes(),
                    )
                  : Text(
                      _notesController.text.isEmpty ? '—' : _notesController.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
              if (widget.isCoach && _notesController.text.trim() != (_notes ?? '')) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    icon: _isSavingNotes ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBg)) : const Icon(Icons.save, size: 18),
                    label: Text(_isSavingNotes ? 'Guardando...' : 'Guardar notas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _neonGreen,
                      foregroundColor: _darkBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    final url = _currentPhotoUrl;
    if (url == null || url.isEmpty) return _buildPlaceholderAvatar();
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: 88,
        height: 88,
        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
      );
    }
    if (url.startsWith('file')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        width: 88,
        height: 88,
        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
      );
    }
    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.person, size: 44, color: Colors.white38),
    );
  }
}
