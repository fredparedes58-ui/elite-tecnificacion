import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/bunny_video_player.dart';

/// ============================================================
/// WIDGET: VideoSyncModal
/// ============================================================
/// Modal para sincronizar eventos Live con el video
/// El usuario marca el momento exacto del pitido inicial
/// ============================================================

class VideoSyncModal extends StatefulWidget {
  final String videoUrl;
  final String? videoGuid;
  final int unsyncedEventsCount;
  final Function(int videoOffset) onSync;

  const VideoSyncModal({
    super.key,
    required this.videoUrl,
    this.videoGuid,
    required this.unsyncedEventsCount,
    required this.onSync,
  });

  @override
  State<VideoSyncModal> createState() => _VideoSyncModalState();
}

class _VideoSyncModalState extends State<VideoSyncModal> {
  final BunnyVideoPlayerController _videoController =
      BunnyVideoPlayerController();

  int _currentVideoSeconds = 0;
  bool _isMarked = false;
  int? _kickoffSecond;

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _markKickoff() {
    final currentSecond = _videoController.getCurrentSeconds() ?? 0;
    setState(() {
      _isMarked = true;
      _kickoffSecond = currentSecond;
    });

    // Pausar el video
    _videoController.pause();

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Pitido inicial marcado en ${_formatTime(currentSecond)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetMark() {
    setState(() {
      _isMarked = false;
      _kickoffSecond = null;
    });
  }

  Future<void> _confirmSync() async {
    if (_kickoffSecond == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes marcar el pitido inicial primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          '¿Confirmar Sincronización?',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se sincronizarán ${widget.unsyncedEventsCount} eventos',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Pitido inicial: ${_formatTime(_kickoffSecond!)}',
              style: const TextStyle(color: Colors.cyan),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('SINCRONIZAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onSync(_kickoffSecond!);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.cyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SINCRONIZAR CON VIDEO',
                        style: GoogleFonts.oswald(
                          color: Colors.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tienes ${widget.unsyncedEventsCount} eventos sin sincronizar',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Player
          Expanded(
            child: Stack(
              children: [
                BunnyVideoPlayer(
                  videoUrl: widget.videoUrl,
                  controller: _videoController,
                  showControls: true,
                  onPositionChanged: (position) {
                    if (mounted) {
                      setState(() {
                        _currentVideoSeconds = position.inSeconds;
                      });
                    }
                  },
                ),

                // Indicador de marca
                if (_isMarked)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'MARCADO EN ${_formatTime(_kickoffSecond!)}',
                            style: GoogleFonts.robotoCondensed(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Timestamp actual
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _formatTime(_currentVideoSeconds),
                      style: GoogleFonts.robotoMono(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instrucciones y botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black,
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instrucciones
                if (!_isMarked) ...[
                  Text(
                    'INSTRUCCIONES:',
                    style: GoogleFonts.robotoCondensed(
                      color: Colors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. ',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(
                          'Reproduce el video y busca el momento exacto del pitido inicial',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. ',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(
                          'Pausa justo cuando el árbitro pita el inicio',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. ',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(
                          'Toca "MARCAR PITIDO INICIAL"',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Botones
                Row(
                  children: [
                    if (_isMarked) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetMark,
                          icon: const Icon(Icons.refresh),
                          label: const Text('REMARCAR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _confirmSync,
                          icon: const Icon(Icons.sync),
                          label: const Text('SINCRONIZAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markKickoff,
                          icon: const Icon(Icons.flag),
                          label: const Text('MARCAR PITIDO INICIAL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
