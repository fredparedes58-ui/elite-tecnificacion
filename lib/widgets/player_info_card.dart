import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerInfoCard extends StatefulWidget {
  final Player player;
  final String playerId;
  final VoidCallback onPhotoUpdated;

  const PlayerInfoCard({
    super.key,
    required this.player,
    required this.playerId,
    required this.onPhotoUpdated,
  });

  @override
  State<PlayerInfoCard> createState() => _PlayerInfoCardState();
}

class _PlayerInfoCardState extends State<PlayerInfoCard> {
  final FileManagementService _fileService = FileManagementService();
  bool _isUploading = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = widget.player.image;
  }

  /// Mostrar diálogo para seleccionar fuente de imagen
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                subtitle: const Text('PC, iCloud, Google Drive'),
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
    if (kIsWeb) {
      _showSnackBar('Cámara no disponible en navegador web', isError: true);
      return;
    }

    final image = await _fileService.pickImageFromCamera();
    if (image != null) {
      await _uploadImage(image);
    }
  }

  /// Seleccionar imagen desde la galería
  Future<void> _pickImageFromGallery() async {
    final image = await _fileService.pickImageFromGallery();
    if (image != null) {
      await _uploadImage(image);
    }
  }

  /// Seleccionar imagen desde explorador de archivos (PC/Nube)
  Future<void> _pickImageFromFiles() async {
    final image = await _fileService.pickFile(
      type: FileType.image,
    );
    if (image != null) {
      await _uploadImage(image);
    }
  }

  /// Subir imagen a Supabase Storage y actualizar BD
  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // 1. Subir a Supabase Storage (bucket: player-photos)
      final imageUrl = await _fileService.uploadImage(
        image: imageFile,
        folder: 'player-photos',
        imageName: 'player_${widget.playerId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl == null) {
        _showSnackBar('Error al subir la imagen', isError: true);
        setState(() => _isUploading = false);
        return;
      }

      // 2. Actualizar base de datos (tabla: profiles, campo: avatar_url)
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', widget.playerId);

      // 3. Actualizar UI local
      setState(() {
        _currentPhotoUrl = imageUrl;
        _isUploading = false;
      });

      _showSnackBar('Foto actualizada correctamente');
      widget.onPhotoUpdated();
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() => _isUploading = false);
    }
  }

  /// Eliminar foto de perfil (volver a default)
  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de que quieres eliminar la foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);

    try {
      // Actualizar BD con imagen por defecto
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': 'assets/players/default.png'})
          .eq('id', widget.playerId);

      setState(() {
        _currentPhotoUrl = 'assets/players/default.png';
        _isUploading = false;
      });

      _showSnackBar('Foto eliminada correctamente');
      widget.onPhotoUpdated();
    } catch (e) {
      _showSnackBar('Error al eliminar: ${e.toString()}', isError: true);
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Player Info', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            // FOTO DE PERFIL CON GESTIÓN
            Stack(
              alignment: Alignment.center,
              children: [
                // Imagen del jugador
                GestureDetector(
                  onTap: _isUploading ? null : _showImageSourceDialog,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      image: _currentPhotoUrl != null && _currentPhotoUrl!.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(_currentPhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _currentPhotoUrl == null || !_currentPhotoUrl!.startsWith('http')
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                
                // Loading indicator
                if (_isUploading)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Botón de editar (overlay)
                if (!_isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Botón de eliminar
                if (!_isUploading && _currentPhotoUrl != null && _currentPhotoUrl!.startsWith('http'))
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _deletePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            Text('Name: ${widget.player.name}'),
            Text('Position: ${widget.player.role ?? "Unknown"}'),
            
            if (!_isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Toca la foto para cambiarla',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
