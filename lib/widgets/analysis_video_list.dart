// ============================================================
// WIDGET: LISTA DE VIDEOS DE ANÁLISIS
// ============================================================
// Muestra los videos de análisis de un jugador
// Permite al entrenador subir nuevos videos
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/player_analysis_video_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/services/media_upload_service.dart';
import 'package:myapp/widgets/video_player_modal.dart';

class AnalysisVideoList extends StatefulWidget {
  final String playerId;
  final bool isCoach; // Solo el entrenador puede subir videos

  const AnalysisVideoList({
    super.key,
    required this.playerId,
    this.isCoach = false,
  });

  @override
  State<AnalysisVideoList> createState() => _AnalysisVideoListState();
}

class _AnalysisVideoListState extends State<AnalysisVideoList> {
  final SupabaseService _supabaseService = SupabaseService();
  final MediaUploadService _mediaService = MediaUploadService();
  final ImagePicker _picker = ImagePicker();

  List<PlayerAnalysisVideo> _videos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);

    final videosData = await _supabaseService.getPlayerAnalysisVideos(
      widget.playerId,
    );

    if (mounted) {
      setState(() {
        _videos = videosData
            .map((data) => PlayerAnalysisVideo.fromJson(data))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!widget.isCoach) {
      _showMessage('Solo el entrenador puede subir videos de análisis');
      return;
    }

    try {
      // Seleccionar video
      final XFile? videoFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (videoFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Subir a Bunny Stream
      final result = await _mediaService.uploadVideo(
        File(videoFile.path),
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      // Obtener teamId
      final teamId = await _getCurrentTeamId();
      if (teamId == null) {
        if (mounted) {
          setState(() => _isUploading = false);
          _showMessage('❌ No se pudo obtener el equipo');
        }
        return;
      }

      // Mostrar diálogo para agregar detalles
      if (mounted) {
        final details = await _showVideoDetailsDialog();
        if (details == null) {
          setState(() => _isUploading = false);
          return;
        }

        // Guardar en Supabase
        final videoData = await _supabaseService
            .savePlayerAnalysisVideoMetadata(
              playerId: widget.playerId,
              teamId: teamId,
              videoUrl: result.directPlayUrl,
              videoGuid: result.guid,
              thumbnailUrl: result.thumbnailUrl,
              title: details['title'] as String,
              comments: details['comments'],
              analysisType: details['type'],
            );

        if (videoData != null) {
          _showMessage('✅ Video subido correctamente');
          _loadVideos();
        } else {
          _showMessage('❌ Error al guardar el video');
        }
      }
    } catch (e) {
      debugPrint('Error subiendo video: $e');
      if (mounted) {
        _showMessage('❌ Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<Map<String, String>?> _showVideoDetailsDialog() async {
    final titleController = TextEditingController();
    final commentsController = TextEditingController();
    String? selectedType = 'technique';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Detalles del Video',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Título',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ej: Mejora en Pases Largos',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Análisis',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: 'technique', child: Text('Técnica')),
                  DropdownMenuItem(
                    value: 'positioning',
                    child: Text('Posicionamiento'),
                  ),
                  DropdownMenuItem(
                    value: 'decision_making',
                    child: Text('Toma de Decisiones'),
                  ),
                  DropdownMenuItem(
                    value: 'fitness',
                    child: Text('Condición Física'),
                  ),
                  DropdownMenuItem(
                    value: 'mental',
                    child: Text('Aspecto Mental'),
                  ),
                ],
                onChanged: (value) => selectedType = value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentarios',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Observaciones técnicas...',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El título es obligatorio')),
                );
                return;
              }
              Navigator.pop<Map<String, String>>(context, {
                'title': titleController.text,
                'comments': commentsController.text,
                'type': selectedType ?? 'technique',
              });
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(PlayerAnalysisVideo video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Eliminar Video',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este video de análisis?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _supabaseService.deletePlayerAnalysisVideo(
        video.id,
      );
      if (success) {
        _showMessage('Video eliminado');
        _loadVideos();
      } else {
        _showMessage('Error al eliminar');
      }
    }
  }

  Future<String?> _getCurrentTeamId() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseService.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['team_id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo teamId: $e');
      return null;
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header con botón de subir (solo entrenador)
        if (widget.isCoach)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadVideo,
              icon: const Icon(Icons.video_call),
              label: const Text('SUBIR VIDEO DE ANÁLISIS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

        // Indicador de carga al subir
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.white12,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Subiendo video... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

        // Lista de videos
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay videos de análisis',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                      if (widget.isCoach) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Sube el primer video de análisis técnico',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVideos,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VideoThumbnailCard(
                          thumbnailUrl: video.thumbnailUrl,
                          title: video.title,
                          subtitle:
                              '${video.analysisTypeLabel} • ${video.timeAgo}',
                          duration: video.formattedDuration,
                          onTap: () {
                            VideoPlayerModal.show(
                              context,
                              videoUrl: video.videoUrl,
                              title: video.title,
                              description: video.comments,
                            );
                          },
                          onDelete: widget.isCoach
                              ? () => _deleteVideo(video)
                              : null,
                          icon: Icons.play_circle_filled,
                          iconColor: colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
