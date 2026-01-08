import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Re-exportar FileType para que sea accesible
export 'package:file_picker/file_picker.dart' show FileType;

/// Servicio centralizado para la gestión de archivos multimedia
/// Soporta imágenes, PDFs y otros documentos
class FileManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  /// Bucket de Supabase donde se almacenarán los archivos
  static const String _defaultBucket = 'app-files';

  // ==================== SELECCIÓN DE ARCHIVOS ====================

  /// Seleccionar una imagen desde la galería
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error al seleccionar imagen desde galería', error: e);
      return null;
    }
  }

  /// Tomar una foto con la cámara
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error al tomar foto con cámara', error: e);
      return null;
    }
  }

  /// Seleccionar un archivo (PDF, documentos, etc.)
  Future<File?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          return File(filePath);
        }
      }
      return null;
    } catch (e) {
      developer.log('Error al seleccionar archivo', error: e);
      return null;
    }
  }

  /// Seleccionar específicamente un PDF
  Future<File?> pickPDF() async {
    return await pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  /// Seleccionar múltiples archivos
  Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      developer.log('Error al seleccionar múltiples archivos', error: e);
      return [];
    }
  }

  // ==================== SUBIDA A SUPABASE STORAGE ====================

  /// Subir un archivo a Supabase Storage
  /// [file] Archivo a subir
  /// [folder] Carpeta dentro del bucket (ej: 'profile-images', 'tactics-pdf')
  /// [fileName] Nombre personalizado (opcional, por defecto usa el nombre del archivo)
  Future<String?> uploadFile({
    required File file,
    String folder = 'general',
    String? fileName,
    String bucket = _defaultBucket,
  }) async {
    try {
      // Generar nombre único si no se proporciona
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.path.split('.').last;
      final name = fileName ?? 'file_$timestamp.$fileExtension';
      
      // Ruta completa en el bucket
      final path = '$folder/$name';

      // Subir archivo
      await _supabase.storage.from(bucket).upload(
        path,
        file,
        fileOptions: FileOptions(
          upsert: false, // No sobreescribir si ya existe
          cacheControl: '3600',
        ),
      );

      // Obtener URL pública del archivo
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      
      developer.log('Archivo subido exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      developer.log('Error al subir archivo a Supabase', error: e);
      return null;
    }
  }

  /// Subir una imagen (optimizado para imágenes)
  Future<String?> uploadImage({
    required File image,
    String folder = 'images',
    String? imageName,
  }) async {
    return await uploadFile(
      file: image,
      folder: folder,
      fileName: imageName,
      bucket: _defaultBucket,
    );
  }

  /// Subir un PDF
  Future<String?> uploadPDF({
    required File pdf,
    String folder = 'documents',
    String? pdfName,
  }) async {
    return await uploadFile(
      file: pdf,
      folder: folder,
      fileName: pdfName,
      bucket: _defaultBucket,
    );
  }

  /// Actualizar foto de perfil de usuario
  Future<String?> updateProfilePicture({
    required String userId,
    required File image,
  }) async {
    try {
      // Subir imagen a carpeta específica de perfiles
      final imageUrl = await uploadImage(
        image: image,
        folder: 'profile-images',
        imageName: 'profile_$userId.jpg',
      );

      if (imageUrl != null) {
        // Actualizar URL en la base de datos del usuario
        await _supabase
            .from('profiles')
            .update({'avatar_url': imageUrl})
            .eq('id', userId);
        
        developer.log('Foto de perfil actualizada para usuario: $userId');
        return imageUrl;
      }
      return null;
    } catch (e) {
      developer.log('Error al actualizar foto de perfil', error: e);
      return null;
    }
  }

  // ==================== ELIMINACIÓN ====================

  /// Eliminar un archivo de Supabase Storage
  Future<bool> deleteFile({
    required String filePath,
    String bucket = _defaultBucket,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
      developer.log('Archivo eliminado: $filePath');
      return true;
    } catch (e) {
      developer.log('Error al eliminar archivo', error: e);
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  /// Obtener el tamaño del archivo en formato legible
  String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Verificar si un archivo es una imagen
  bool isImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// Verificar si un archivo es un PDF
  bool isPDF(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  /// Mostrar diálogo de selección (Galería o Cámara)
  static Future<File?> showImageSourceDialog(BuildContext context, FileManagementService service) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar origen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  final image = await service.pickImageFromGallery();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () async {
                  final image = await service.pickImageFromCamera();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== WIDGETS HELPER ====================

/// Widget para mostrar selector de archivos con botones
class FileUploadWidget extends StatelessWidget {
  final Function(File) onFileSelected;
  final FileManagementService fileService = FileManagementService();
  final String title;
  final FileType fileType;

  FileUploadWidget({
    super.key,
    required this.onFileSelected,
    this.title = 'Seleccionar archivo',
    this.fileType = FileType.any,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final file = await fileService.pickFile(type: fileType);
        if (file != null) {
          onFileSelected(file);
        }
      },
      icon: const Icon(Icons.upload_file),
      label: Text(title),
    );
  }
}
