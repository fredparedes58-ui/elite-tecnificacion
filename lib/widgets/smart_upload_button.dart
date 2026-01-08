import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/media_upload_service.dart';

/// ============================================================
/// SMART UPLOAD BUTTON - COMPONENTE REUTILIZABLE
/// ============================================================
/// Widget inteligente para subir fotos o videos con:
/// - Selector de fuente (Cámara/Galería)
/// - Indicador de progreso en tiempo real
/// - Bloqueo durante la subida
/// - Manejo de errores
/// ============================================================

class SmartUploadButton extends StatefulWidget {
  /// Tipo de media a subir
  final MediaType mediaType;
  
  /// Callback cuando la subida es exitosa
  final Function(String url) onUploadSuccess;
  
  /// Callback opcional para errores
  final Function(String error)? onUploadError;
  
  /// Texto del botón
  final String? buttonText;
  
  /// Icono del botón
  final IconData? buttonIcon;
  
  /// Color del botón
  final Color? buttonColor;

  const SmartUploadButton({
    super.key,
    required this.mediaType,
    required this.onUploadSuccess,
    this.onUploadError,
    this.buttonText,
    this.buttonIcon,
    this.buttonColor,
  });

  @override
  State<SmartUploadButton> createState() => _SmartUploadButtonState();
}

class _SmartUploadButtonState extends State<SmartUploadButton> {
  final ImagePicker _picker = ImagePicker();
  final MediaUploadService _uploadService = MediaUploadService();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BOTÓN DE SUBIDA
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _showSourceSelector,
          icon: _isUploading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  widget.buttonIcon ?? 
                  (widget.mediaType == MediaType.photo 
                      ? Icons.add_photo_alternate 
                      : Icons.video_call),
                ),
          label: Text(
            _isUploading 
                ? 'Subiendo...' 
                : widget.buttonText ?? 
                  (widget.mediaType == MediaType.photo 
                      ? 'Subir Foto' 
                      : 'Subir Video'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.buttonColor ?? theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // BARRA DE PROGRESO (solo para videos)
        if (_isUploading && widget.mediaType == MediaType.video) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subiendo video...',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // SPINNER PARA FOTOS
        if (_isUploading && widget.mediaType == MediaType.photo) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Subiendo foto...',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Muestra el selector de fuente (Cámara/Galería)
  Future<void> _showSourceSelector() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Seleccionar fuente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // CÁMARA
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Cámara'),
              subtitle: Text(
                widget.mediaType == MediaType.photo 
                    ? 'Tomar una foto' 
                    : 'Grabar un video',
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),

            const SizedBox(height: 8),

            // GALERÍA
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text('Galería'),
              subtitle: Text(
                widget.mediaType == MediaType.photo 
                    ? 'Seleccionar una foto' 
                    : 'Seleccionar un video',
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      await _pickAndUpload(source);
    }
  }

  /// Selecciona y sube el archivo
  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      // SELECCIONAR ARCHIVO
      XFile? pickedFile;
      
      if (widget.mediaType == MediaType.photo) {
        pickedFile = await _picker.pickImage(source: source);
      } else {
        pickedFile = await _picker.pickVideo(source: source);
      }

      if (pickedFile == null) {
        debugPrint('📁 Usuario canceló la selección');
        return;
      }

      final file = File(pickedFile.path);
      debugPrint('📁 Archivo seleccionado: ${file.path}');

      // INICIAR SUBIDA
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      String resultUrl;

      if (widget.mediaType == MediaType.photo) {
        // SUBIR FOTO A R2
        resultUrl = await _uploadService.uploadPhoto(file);
      } else {
        // SUBIR VIDEO A BUNNY STREAM
        final result = await _uploadService.uploadVideo(
          file,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
        resultUrl = result.directPlayUrl;
      }

      // ÉXITO
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      widget.onUploadSuccess(resultUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.mediaType == MediaType.photo 
                        ? '✅ Foto subida exitosamente' 
                        : '✅ Video subido exitosamente',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ERROR
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      final errorMessage = 'Error al subir: ${e.toString()}';
      widget.onUploadError?.call(errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// ============================================================
/// ENUMS
/// ============================================================

enum MediaType {
  photo,
  video,
}
