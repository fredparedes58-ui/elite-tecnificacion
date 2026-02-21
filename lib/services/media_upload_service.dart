import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:myapp/config/media_config.dart';

/// ============================================================
/// SERVICIO CENTRAL DE SUBIDA DE MEDIA
/// ============================================================
/// Gestiona la subida de archivos multimedia con separación estricta:
/// - Imágenes → Cloudflare R2 (S3-compatible)
/// - Videos → Bunny Stream
/// ============================================================

class MediaUploadService {
  late final Minio _minioClient;
  late final Dio _dio;
  final Uuid _uuid = const Uuid();

  MediaUploadService() {
    // Inicializar cliente Minio para R2
    _minioClient = Minio(
      endPoint: MediaConfig.r2Endpoint.replaceAll('https://', ''),
      accessKey: MediaConfig.r2AccessKey,
      secretKey: MediaConfig.r2SecretKey,
      useSSL: true,
    );

    // Inicializar Dio para Bunny Stream
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 10),
      ),
    );
  }

  // ==========================================
  // MÉTODO A: SUBIDA DE FOTOS A R2
  // ==========================================

  /// Sube una imagen a Cloudflare R2
  /// 
  /// [file] - Archivo de imagen a subir
  /// Returns: URL pública de la imagen subida
  Future<String> uploadPhoto(File file) async {
    try {
      debugPrint('📸 Iniciando subida de foto a R2...');
      
      // Generar nombre único
      final extension = path.extension(file.path);
      final fileName = '${_uuid.v4()}$extension';
      final objectName = 'photos/$fileName';

      // Leer bytes del archivo
      final bytes = await file.readAsBytes();
      final stream = Stream.value(bytes);

      // Determinar Content-Type
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      } else if (extension.toLowerCase() == '.gif') {
        contentType = 'image/gif';
      }

      debugPrint('📦 Subiendo a R2: $objectName');
      debugPrint('📋 Content-Type: $contentType');

      // Subir a R2
      await _minioClient.putObject(
        MediaConfig.r2BucketName,
        objectName,
        stream,
        size: bytes.length,
        onProgress: (sent) {
          final progress = (sent / bytes.length * 100).toStringAsFixed(1);
          debugPrint('⬆️ Progreso R2: $progress%');
        },
        metadata: {
          'Content-Type': contentType,
        },
      );

      // Construir URL pública
      final publicUrl = '${MediaConfig.r2PublicUrl}/$objectName';
      
      debugPrint('✅ Foto subida exitosamente');
      debugPrint('🔗 URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error subiendo foto a R2: $e');
      rethrow;
    }
  }

  // ==========================================
  // MÉTODO B: SUBIDA DE VIDEOS A BUNNY STREAM
  // ==========================================

  /// Sube un video a Bunny Stream con seguimiento de progreso
  /// 
  /// [file] - Archivo de video a subir
  /// [onProgress] - Callback para actualizar el progreso (0.0 - 1.0)
  /// Returns: Objeto con información del video subido
  Future<BunnyVideoResult> uploadVideo(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('🎥 Iniciando subida de video a Bunny Stream...');

      // PASO 1: Crear el video en Bunny y obtener GUID
      final createResponse = await _dio.post(
        '${MediaConfig.bunnyStreamEndpoint}/library/${MediaConfig.bunnyLibraryId}/videos',
        options: Options(
          headers: {
            'AccessKey': MediaConfig.bunnyApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'title': path.basenameWithoutExtension(file.path),
        },
      );

      final guid = createResponse.data['guid'] as String;
      final videoId = createResponse.data['videoLibraryId'] as int;
      
      debugPrint('📝 Video creado con GUID: $guid');

      // PASO 2: Subir el archivo del video con tracking de progreso
      final uploadUrl = '${MediaConfig.bunnyStreamEndpoint}/library/${MediaConfig.bunnyLibraryId}/videos/$guid';
      
      final bytes = await file.readAsBytes();
      
      debugPrint('📤 Subiendo archivo... (${_formatBytes(bytes.length)})');

      await _dio.put(
        uploadUrl,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {
            'AccessKey': MediaConfig.bunnyApiKey,
            'Content-Type': 'application/octet-stream',
          },
          contentType: 'application/octet-stream',
        ),
        onSendProgress: (sent, total) {
          final progress = sent / total;
          debugPrint('⬆️ Progreso Bunny: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress?.call(progress);
        },
      );

      debugPrint('✅ Video subido exitosamente');

      // Construir URLs
      final directPlayUrl = 'https://${MediaConfig.bunnyCdnHostname}/$guid/playlist.m3u8';
      final thumbnailUrl = 'https://${MediaConfig.bunnyCdnHostname}/$guid/thumbnail.jpg';

      debugPrint('🔗 Direct Play URL: $directPlayUrl');
      debugPrint('🖼️ Thumbnail URL: $thumbnailUrl');

      return BunnyVideoResult(
        guid: guid,
        videoLibraryId: videoId,
        directPlayUrl: directPlayUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('❌ Error subiendo video a Bunny Stream: $e');
      if (e is DioException) {
        debugPrint('❌ Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Formatea bytes a formato legible
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Verifica si un archivo es una imagen
  bool isImage(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext);
  }

  /// Verifica si un archivo es un video
  bool isVideo(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext);
  }
}

/// ============================================================
/// MODELO DE RESULTADO DE BUNNY STREAM
/// ============================================================

class BunnyVideoResult {
  final String guid;
  final int videoLibraryId;
  final String directPlayUrl;
  final String thumbnailUrl;

  BunnyVideoResult({
    required this.guid,
    required this.videoLibraryId,
    required this.directPlayUrl,
    required this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
    'guid': guid,
    'videoLibraryId': videoLibraryId,
    'directPlayUrl': directPlayUrl,
    'thumbnailUrl': thumbnailUrl,
  };

  @override
  String toString() => 'BunnyVideoResult(guid: $guid, playUrl: $directPlayUrl)';
}
