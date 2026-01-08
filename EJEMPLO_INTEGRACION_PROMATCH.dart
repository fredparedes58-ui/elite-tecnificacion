/// ============================================================
/// EJEMPLO DE INTEGRACIÓN: ProMatch Analysis
/// ============================================================
/// Este archivo muestra cómo integrar ProMatchAnalysisScreen
/// en diferentes pantallas de tu app
/// ============================================================

import 'package:flutter/material.dart';
import 'package:myapp/screens/promatch_analysis_screen.dart';

/// ============================================================
/// EJEMPLO 1: Botón en Home Screen
/// ============================================================
/// Añade este botón en tu home_screen.dart dentro del grid
/// de QuickAccess o como un QuickActionButton

class HomeScreenProMatchButton extends StatelessWidget {
  const HomeScreenProMatchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // VIDEO DE PRUEBA: Reemplaza con tu URL real
        const testVideoUrl = 'https://vz-xxx.b-cdn.net/VIDEO_GUID/playlist.m3u8';
        const testVideoGuid = 'tu-video-guid-aqui';
        const testMatchId = 'tu-match-id-aqui';
        const testTeamId = 'tu-team-id-aqui';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProMatchAnalysisScreen(
              videoUrl: testVideoUrl,
              videoGuid: testVideoGuid,
              matchId: testMatchId,
              teamId: testTeamId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.2),
              Colors.purple.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.analytics,
                color: Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ProMatch',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// EJEMPLO 2: Desde Pantalla de Partido
/// ============================================================
/// Usa este botón en match_details_screen.dart o similar

class MatchAnalysisButton extends StatelessWidget {
  final String matchId;
  final String teamId;
  final String? videoUrl;
  final String? videoGuid;

  const MatchAnalysisButton({
    super.key,
    required this.matchId,
    required this.teamId,
    this.videoUrl,
    this.videoGuid,
  });

  @override
  Widget build(BuildContext context) {
    // Solo mostrar si hay video disponible
    if (videoUrl == null || videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.video_library),
      label: const Text('ANÁLISIS COMPLETO'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProMatchAnalysisScreen(
              videoUrl: videoUrl!,
              videoGuid: videoGuid,
              matchId: matchId,
              teamId: teamId,
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================
/// EJEMPLO 3: Después de Subir un Video
/// ============================================================
/// Usa esto después de subir un video con MediaUploadService

/*
import 'package:myapp/services/media_upload_service.dart';

Future<void> uploadAndAnalyzeVideo(BuildContext context, File videoFile) async {
  final mediaService = MediaUploadService();
  
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.cyan),
          SizedBox(height: 16),
          Text('Subiendo video...'),
        ],
      ),
    ),
  );
  
  try {
    // Subir a Bunny Stream
    final result = await mediaService.uploadVideo(videoFile);
    
    // Cerrar loading
    Navigator.of(context).pop();
    
    // Abrir análisis inmediatamente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProMatchAnalysisScreen(
          videoUrl: result.directPlayUrl,
          videoGuid: result.guid,
          matchId: currentMatchId, // Obtén del contexto
          teamId: currentTeamId,   // Obtén del contexto
        ),
      ),
    );
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al subir video: $e')),
    );
  }
}
*/

/// ============================================================
/// EJEMPLO 4: Lista de Videos con Análisis
/// ============================================================
/// Card para mostrar en una lista de videos con botón de análisis

class VideoAnalysisCard extends StatelessWidget {
  final String videoTitle;
  final String videoUrl;
  final String videoGuid;
  final String thumbnailUrl;
  final String? matchId;
  final String teamId;
  final DateTime uploadedAt;

  const VideoAnalysisCard({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
    required this.videoGuid,
    required this.thumbnailUrl,
    required this.teamId,
    this.matchId,
    required this.uploadedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[900],
                      child: const Icon(Icons.video_library, size: 64),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.cyan, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'ANÁLISIS',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(uploadedAt),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botón de análisis
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('ANALIZAR PARTIDO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProMatchAnalysisScreen(
                            videoUrl: videoUrl,
                            videoGuid: videoGuid,
                            matchId: matchId,
                            teamId: teamId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// ============================================================
/// EJEMPLO 5: Menú Flotante de Análisis
/// ============================================================
/// FloatingActionButton que muestra opciones de análisis

class AnalysisFloatingButton extends StatelessWidget {
  final String currentMatchId;
  final String currentTeamId;

  const AnalysisFloatingButton({
    super.key,
    required this.currentMatchId,
    required this.currentTeamId,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAnalysisOptions(context),
      backgroundColor: Colors.cyan,
      icon: const Icon(Icons.analytics, color: Colors.black),
      label: const Text(
        'ANÁLISIS',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAnalysisOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Título
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'HERRAMIENTAS DE ANÁLISIS',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            // Opciones
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.cyan),
              title: const Text('ProMatch Analysis',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Video + Voz + Dibujo',
                  style: TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.pop(context);
                // Aquí deberías obtener la URL del video del partido
                // Por ahora usamos un ejemplo:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProMatchAnalysisScreen(
                      videoUrl: 'https://tu-video-url.m3u8',
                      videoGuid: 'tu-guid',
                      matchId: 'match-id',
                      teamId: 'team-id',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// CÓMO USAR ESTOS EJEMPLOS
/// ============================================================
/*

1. BOTÓN EN HOME SCREEN:
   - Copia HomeScreenProMatchButton
   - Añádelo al grid de QuickAccess en home_screen.dart

2. DESDE PANTALLA DE PARTIDO:
   - Usa MatchAnalysisButton en tu match details screen
   - Pasa el matchId, teamId y videoUrl del partido

3. DESPUÉS DE SUBIR VIDEO:
   - Usa la función uploadAndAnalyzeVideo
   - Llámala después de que el usuario seleccione un video

4. LISTA DE VIDEOS:
   - Usa VideoAnalysisCard en un ListView
   - Muestra todos los videos disponibles

5. FLOATING BUTTON:
   - Usa AnalysisFloatingButton como FAB
   - Muestra opciones de análisis disponibles

*/
