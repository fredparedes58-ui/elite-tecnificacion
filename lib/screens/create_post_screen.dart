// ============================================================
// CREATE POST SCREEN - Crear publicaciones sociales
// ============================================================
// Pantalla para subir fotos/videos y publicar en el feed
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_post_model.dart';
import '../services/social_service.dart';
import 'victory_share_screen.dart';
import '../services/media_upload_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String teamId;
  final SocialPostScope? defaultScope; // Scope por defecto

  const CreatePostScreen({super.key, required this.teamId, this.defaultScope});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final SocialService _socialService = SocialService();
  final MediaUploadService _mediaService = MediaUploadService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  MediaType? _mediaType;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  SocialPostScope _selectedScope = SocialPostScope.team;
  bool _isCoach = false;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.defaultScope ?? SocialPostScope.team;
    _checkUserRole();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('team_id', widget.teamId)
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _mediaType = MediaType.image;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        setState(() {
          _selectedFile = File(video.path);
          _mediaType = MediaType.video;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedFile = File(photo.path);
          _mediaType = MediaType.image;
        });
      }
    } catch (e) {
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _publishPost() async {
    if (_selectedFile == null || _mediaType == null) {
      _showError('Por favor selecciona una imagen o video');
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _showError('Usuario no autenticado');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Subir archivo a R2/Bunny/Storage
      final String mediaUrl = await _uploadMedia();

      // 2. Crear el post en Supabase
      final postDto = CreateSocialPostDto(
        teamId: widget.teamId,
        userId: currentUser.id,
        contentText: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mediaUrl: mediaUrl,
        mediaType: _mediaType!,
        thumbnailUrl: null, // TODO: Generar thumbnail para videos
        scope: _selectedScope,
      );

      await _socialService.createPost(postDto: postDto);

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación compartida!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error al publicar: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String> _uploadMedia() async {
    if (_selectedFile == null) throw Exception('No hay archivo seleccionado');

    setState(() => _uploadProgress = 0.0);

    try {
      String mediaUrl;
      if (_mediaType == MediaType.image) {
        mediaUrl = await _mediaService.uploadPhoto(_selectedFile!);
      } else {
        final result = await _mediaService.uploadVideo(
          _selectedFile!,
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
        mediaUrl = result.directPlayUrl;
      }
      setState(() => _uploadProgress = 1.0);
      return mediaUrl;
    } catch (e) {
      throw Exception('Error subiendo archivo: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _navigateToVictoryShare() async {
    if (_selectedFile == null || _mediaType != MediaType.image) {
      _showError('Solo puedes usar Victory Share con imágenes');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VictoryShareScreen(imageFile: _selectedFile!),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: Text(
                  'Galería de Fotos',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.purple),
                title: Text(
                  'Galería de Videos',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: Text(
                  'Tomar Foto',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'NUEVA PUBLICACIÓN',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: theme.primaryColor,
          ),
        ),
        actions: [
          if (_selectedFile != null && !_isUploading)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.primaryColor),
              color: const Color(0xFF1D1E33),
              onSelected: (value) {
                if (value == 'victory') {
                  _navigateToVictoryShare();
                } else {
                  _publishPost();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'normal',
                  child: Row(
                    children: [
                      const Icon(Icons.send, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text(
                        'Publicar Normal',
                        style: GoogleFonts.roboto(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (_mediaType == MediaType.image)
                  PopupMenuItem(
                    value: 'victory',
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          'Victory Share',
                          style: GoogleFonts.roboto(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: _isUploading ? _buildUploadingState() : _buildForm(),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _uploadProgress,
            strokeWidth: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subiendo... ${(_uploadProgress * 100).toInt()}%',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vista previa del archivo seleccionado
          if (_selectedFile != null) _buildPreview(),

          const SizedBox(height: 16),

          // Botón para seleccionar media
          if (_selectedFile == null)
            _buildSelectMediaButton()
          else
            ElevatedButton.icon(
              onPressed: _showMediaSourceDialog,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('CAMBIAR ARCHIVO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

          const SizedBox(height: 24),

          // Selector de scope (solo para coaches)
          if (_isCoach) _buildScopeSelector(),

          const SizedBox(height: 24),

          // Campo de descripción
          Text(
            'Descripción (Opcional)',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            style: GoogleFonts.roboto(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Escribe algo sobre esta publicación...',
              hintStyle: GoogleFonts.roboto(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1D1E33),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón de publicar (solo si hay archivo seleccionado)
          if (_selectedFile != null)
            ElevatedButton.icon(
              onPressed: _publishPost,
              icon: const Icon(Icons.send),
              label: Text(
                'PUBLICAR AHORA',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectMediaButton() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _showMediaSourceDialog,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Toca para seleccionar',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Foto o Video',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _mediaType == MediaType.image
            ? Image.file(
                _selectedFile!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Video seleccionado',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildScopeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Dónde publicar?',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildScopeOption(
                scope: SocialPostScope.team,
                icon: Icons.groups,
                title: 'Mi Equipo',
                subtitle: 'Solo tu equipo',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScopeOption(
                scope: SocialPostScope.school,
                icon: Icons.school,
                title: 'Todo el Club',
                subtitle: 'Todos los equipos',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScopeOption({
    required SocialPostScope scope,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => setState(() => _selectedScope = scope),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white54, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white70,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
