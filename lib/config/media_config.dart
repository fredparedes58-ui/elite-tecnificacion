/// ============================================================
/// CONFIGURACIÓN DE MEDIA UPLOAD
/// ============================================================
/// Credenciales para Cloudflare R2 (imágenes) y Bunny Stream (videos)
/// ============================================================

class MediaConfig {
  // --- CLOUDFLARE R2 (FOTOS) ---
  static const String r2Endpoint = "https://cf60f9bc215ffa03c9dcbf139e1f9e8b.r2.cloudflarestorage.com";
  static const String r2AccessKey = "6cb92b2fff1fd2237f44087e3f40afa4";
  static const String r2SecretKey = "QG0bCW_m2GYHLC-zneXqTrpyGXHxw_iqsjyFChR8";
  static const String r2BucketName = "futbol-media-app";
  static const String r2PublicUrl = "https://futbol-media-app.celiannycastro.workers.dev"; // Configura tu Worker/Domain

  // --- BUNNY STREAM (VIDEO) ---
  static const String bunnyApiKey = "49aec20a-50cb-4d2d-b2fd072ac61b-6e05-4d7c";
  static const String bunnyLibraryId = "575748";
  static const String bunnyCdnHostname = "vz-cc855308-31c.b-cdn.net";
  static const String bunnyStreamEndpoint = "https://video.bunnycdn.com";

  // Constructor privado para evitar instanciación
  MediaConfig._();
}
