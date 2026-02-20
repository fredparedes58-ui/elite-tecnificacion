/// ============================================================
/// CONFIGURACIÓN DE MEDIA UPLOAD
/// ============================================================
/// Credenciales para Cloudflare R2 (imágenes) y Bunny Stream (videos)
/// Lee desde variables de entorno (.env) para seguridad
/// ============================================================
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaConfig {
  // --- CLOUDFLARE R2 (FOTOS) ---
  static String get r2Endpoint =>
      dotenv.env['R2_ENDPOINT'] ?? _throwMissingEnvError('R2_ENDPOINT');

  static String get r2AccessKey =>
      dotenv.env['R2_ACCESS_KEY'] ?? _throwMissingEnvError('R2_ACCESS_KEY');

  static String get r2SecretKey =>
      dotenv.env['R2_SECRET_KEY'] ?? _throwMissingEnvError('R2_SECRET_KEY');

  static String get r2BucketName =>
      dotenv.env['R2_BUCKET_NAME'] ?? _throwMissingEnvError('R2_BUCKET_NAME');

  static String get r2PublicUrl =>
      dotenv.env['R2_PUBLIC_URL'] ?? _throwMissingEnvError('R2_PUBLIC_URL');

  // --- BUNNY STREAM (VIDEO) ---
  static String get bunnyApiKey =>
      dotenv.env['BUNNY_API_KEY'] ?? _throwMissingEnvError('BUNNY_API_KEY');

  static String get bunnyLibraryId =>
      dotenv.env['BUNNY_LIBRARY_ID'] ??
      _throwMissingEnvError('BUNNY_LIBRARY_ID');

  static String get bunnyCdnHostname =>
      dotenv.env['BUNNY_CDN_HOSTNAME'] ??
      _throwMissingEnvError('BUNNY_CDN_HOSTNAME');

  static String get bunnyStreamEndpoint =>
      dotenv.env['BUNNY_STREAM_ENDPOINT'] ??
      _throwMissingEnvError('BUNNY_STREAM_ENDPOINT');

  // Constructor privado para evitar instanciación
  MediaConfig._();

  /// Lanza error si falta una variable de entorno crítica
  static String _throwMissingEnvError(String key) {
    throw Exception(
      '❌ ERROR DE CONFIGURACIÓN:\n'
      'Variable de entorno "$key" no encontrada.\n\n'
      'Solución:\n'
      '1. Copia .env.example a .env\n'
      '2. Rellena las credenciales reales para R2 y Bunny Stream\n'
      '3. Reinicia la app\n\n'
      'Ver: SECURITY_SETUP.md',
    );
  }
}
