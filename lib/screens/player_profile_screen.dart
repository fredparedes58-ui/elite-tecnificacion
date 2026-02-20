// ============================================================
// PANTALLA: PERFIL DEL JUGADOR CON ANÁLISIS DE VIDEO
// ============================================================
// Perfil completo del jugador con pestaña de análisis privado
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/player_stats.dart';
import 'package:myapp/widgets/analysis_video_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/services/file_management_service.dart'
    show FileManagementService, FileType;

class PlayerProfileScreen extends StatefulWidget {
  final Player player;

  const PlayerProfileScreen({super.key, required this.player});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCoach = false;
  final FileManagementService _fileService = FileManagementService();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Verificar si el usuario actual es entrenador
      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _isCoach = ['coach', 'admin'].contains(response['role']);
        });
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.player.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.video_library), text: 'Análisis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PERFIL BÁSICO
          _buildProfileTab(textTheme, colorScheme),

          // TAB 2: ANÁLISIS DE VIDEO (PRIVADO)
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab(TextTheme textTheme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA: Información del jugador
          Expanded(flex: 3, child: _buildLeftColumn(colorScheme)),
          const SizedBox(width: 16),
          // COLUMNA DERECHA: Estadísticas
          Expanded(flex: 4, child: _buildRightColumn(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card del jugador con avatar y nombre
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.3),
                colorScheme.secondary.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Avatar (clickeable para subir foto - solo entrenador)
              GestureDetector(
                onTap:
                    _isCoach && !_isUploadingPhoto && widget.player.id != null
                    ? () => _showImageSourceDialog()
                    : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.player.image.startsWith('http')
                          ? NetworkImage(widget.player.image)
                          : (widget.player.image.startsWith('assets/')
                                ? AssetImage(widget.player.image)
                                      as ImageProvider
                                : null),
                      backgroundColor: Colors.grey[800],
                      child:
                          widget.player.image.isEmpty ||
                              (!widget.player.image.startsWith('http') &&
                                  !widget.player.image.startsWith('assets/'))
                          ? Icon(Icons.person, size: 50, color: Colors.white54)
                          : null,
                    ),
                    // Indicador de carga
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Icono de cámara si es entrenador
                    if (_isCoach &&
                        !_isUploadingPhoto &&
                        widget.player.id != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Nombre
              Text(
                widget.player.name,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Tags (U18, BEGINNER, etc.)
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildTag('U18', Colors.teal),
                  _buildTag('BEGINNER', Colors.purple),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Información: Posición
        if (widget.player.role != null)
          _buildInfoRow(Icons.location_on, 'Posición: ${widget.player.role}'),
        const SizedBox(height: 8),
        // Información: Edad (placeholder, necesitarías agregar edad al modelo)
        // TODO: obtener edad de BD cuando esté disponible
        _buildInfoRow(Icons.calendar_today, '16 años'),
        const SizedBox(height: 16),
        // Notas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notas',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getPlayerNotes(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              if (_isCoach) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showEditNotesDialog(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar notas'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(ColorScheme colorScheme) {
    final stats = widget.player.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón EDITAR STATS (solo entrenador)
        if (_isCoach)
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton.icon(
              onPressed: () => _showEditStatsDialog(),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('EDITAR STATS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.purple,
                side: BorderSide(color: Colors.purple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_isCoach) const SizedBox(height: 16),
        // Gráfico Radar
        _buildRadarChart(stats, colorScheme),
        const SizedBox(height: 24),
        // Barras de progreso individuales
        _buildStatBars(stats, colorScheme),
        const SizedBox(height: 16),
        // Puntuación General
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Puntuación General',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats.generalScore.toStringAsFixed(0),
                style: GoogleFonts.oswald(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header de privacidad
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isCoach
                        ? 'Videos privados. Solo visibles para ti y el jugador.'
                        : 'Videos de análisis técnico de tu entrenador.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Lista de videos
          Expanded(
            child: AnalysisVideoList(
              playerId: widget.player.id ?? '',
              isCoach: _isCoach,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildRadarChart(PlayerStats stats, ColorScheme colorScheme) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: colorScheme.primary.withValues(alpha: 0.3),
              borderColor: colorScheme.primary,
              borderWidth: 2,
              dataEntries: [
                RadarEntry(value: stats.velocidad),
                RadarEntry(value: stats.tecnica),
                RadarEntry(value: stats.fisico),
                RadarEntry(value: stats.mental),
                RadarEntry(value: stats.tactico),
              ],
            ),
          ],
          titlePositionPercentageOffset: 0.15,
          getTitle: (index, angle) {
            String title;
            switch (index) {
              case 0:
                title = 'VELOCIDAD';
                break;
              case 1:
                title = 'TÉCN';
                break;
              case 2:
                title = 'FÍSICO';
                break;
              case 3:
                title = 'MENTAL';
                break;
              case 4:
                title = 'TÁCTICO';
                break;
              default:
                title = '';
            }
            return RadarChartTitle(text: title, angle: angle);
          },
          titleTextStyle: GoogleFonts.robotoCondensed(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.white54),
          tickCount: 5,
          radarShape: RadarShape.polygon,
        ),
      ),
    );
  }

  Widget _buildStatBars(PlayerStats stats, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildStatBar('Velocidad', stats.velocidad, colorScheme),
          const SizedBox(height: 12),
          _buildStatBar('Técnica', stats.tecnica, colorScheme),
          const SizedBox(height: 12),
          _buildStatBar('Físico', stats.fisico, colorScheme),
          const SizedBox(height: 12),
          _buildStatBar('Mental', stats.mental, colorScheme),
          const SizedBox(height: 12),
          _buildStatBar('Táctico', stats.tactico, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, ColorScheme colorScheme) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white12,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            value.toStringAsFixed(0),
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getPlayerNotes() {
    return widget.player.statusNote ??
        'Jugador con gran potencial en técnica. Muy dedicado.';
  }

  Future<void> _showEditNotesDialog() async {
    final TextEditingController notesController = TextEditingController(
      text: _getPlayerNotes(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'Editar Notas',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: TextField(
          controller: notesController,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Escribe notas sobre el jugador...',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _savePlayerNotes(notesController.text.trim());
              if (context.mounted) {
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlayerNotes(String notes) async {
    if (widget.player.id == null) return;

    try {
      await Supabase.instance.client
          .from('team_members')
          .update({'status_note': notes})
          .eq('user_id', widget.player.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notas actualizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando notas: $e');
    }
  }

  Future<void> _showEditStatsDialog() async {
    if (!_isCoach) return;

    final stats = widget.player.stats;
    final velocidadController = TextEditingController(
      text: stats.velocidad.toStringAsFixed(0),
    );
    final tecnicaController = TextEditingController(
      text: stats.tecnica.toStringAsFixed(0),
    );
    final fisicoController = TextEditingController(
      text: stats.fisico.toStringAsFixed(0),
    );
    final mentalController = TextEditingController(
      text: stats.mental.toStringAsFixed(0),
    );
    final tacticoController = TextEditingController(
      text: stats.tactico.toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            title: Text(
              'Editar Estadísticas',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatSlider(
                    'Velocidad',
                    double.tryParse(velocidadController.text) ?? 0,
                    (value) {
                      velocidadController.text = value.toStringAsFixed(0);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStatSlider(
                    'Técnica',
                    double.tryParse(tecnicaController.text) ?? 0,
                    (value) {
                      tecnicaController.text = value.toStringAsFixed(0);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStatSlider(
                    'Físico',
                    double.tryParse(fisicoController.text) ?? 0,
                    (value) {
                      fisicoController.text = value.toStringAsFixed(0);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStatSlider(
                    'Mental',
                    double.tryParse(mentalController.text) ?? 0,
                    (value) {
                      mentalController.text = value.toStringAsFixed(0);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStatSlider(
                    'Táctico',
                    double.tryParse(tacticoController.text) ?? 0,
                    (value) {
                      tacticoController.text = value.toStringAsFixed(0);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _savePlayerStats(
                    double.tryParse(velocidadController.text) ?? 0,
                    double.tryParse(tecnicaController.text) ?? 0,
                    double.tryParse(fisicoController.text) ?? 0,
                    double.tryParse(mentalController.text) ?? 0,
                    double.tryParse(tacticoController.text) ?? 0,
                  );
                  if (context.mounted) {
                    navigator.pop();
                    setState(() {}); // Recargar para mostrar nuevos valores
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatSlider(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Colors.white12,
        ),
      ],
    );
  }

  Future<void> _savePlayerStats(
    double velocidad,
    double tecnica,
    double fisico,
    double mental,
    double tactico,
  ) async {
    if (widget.player.id == null) return;

    try {
      final statsMap = {
        'velocidad': velocidad,
        'tecnica': tecnica,
        'fisico': fisico,
        'mental': mental,
        'tactico': tactico,
      };

      await Supabase.instance.client
          .from('profiles')
          .update({'attributes': statsMap})
          .eq('id', widget.player.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estadísticas actualizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando estadísticas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar estadísticas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra el diálogo para seleccionar fuente de imagen
  void _showImageSourceDialog() {
    if (widget.player.id == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Cambiar avatar de ${widget.player.name}',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar Foto'),
                subtitle: const Text('Usar cámara del dispositivo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Galería'),
                subtitle: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.orange),
                title: const Text('Explorador de Archivos'),
                subtitle: const Text('PC, iCloud, Google Drive, etc.'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromFiles();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Seleccionar imagen desde la cámara
  Future<void> _pickImageFromCamera() async {
    final image = await _fileService.pickImageFromCamera();
    if (image != null) {
      await _uploadPlayerImage(image);
    }
  }

  /// Seleccionar imagen desde la galería
  Future<void> _pickImageFromGallery() async {
    final image = await _fileService.pickImageFromGallery();
    if (image != null) {
      await _uploadPlayerImage(image);
    }
  }

  /// Seleccionar imagen desde explorador de archivos
  Future<void> _pickImageFromFiles() async {
    final image = await _fileService.pickFile(type: FileType.image);
    if (image != null && _fileService.isImage(image)) {
      await _uploadPlayerImage(image);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una imagen válida'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Subir imagen del jugador a Supabase Storage y actualizar BD
  Future<void> _uploadPlayerImage(File imageFile) async {
    if (widget.player.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: El jugador no tiene ID válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // 1. Subir a Supabase Storage (bucket: player-photos)
      final imageUrl = await _fileService.uploadImage(
        image: imageFile,
        folder: 'player-photos',
        imageName:
            'player_${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la imagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // 2. Actualizar base de datos (tabla: profiles, campo: avatar_url)
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', widget.player.id!);

      // 3. Actualizar estado
      setState(() {
        _isUploadingPhoto = false;
      });

      // 4. Recargar datos del jugador para actualizar la imagen
      // El widget se reconstruirá automáticamente cuando navegues de vuelta
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar actualizado: ${widget.player.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Notificar al padre para que recargue si es necesario
        // Por ahora, el usuario necesitará recargar manualmente
      }
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}
