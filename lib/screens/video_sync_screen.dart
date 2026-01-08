import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/bunny_video_player.dart';

/// ============================================================
/// PANTALLA: VideoSyncScreen
/// ============================================================
/// Permite sincronizar eventos Live con el video del partido
/// El usuario marca el momento exacto del pitido inicial en el video
/// y el sistema calcula el offset para actualizar todos los eventos
/// ============================================================

class VideoSyncScreen extends StatefulWidget {
  final String matchId;
  final String videoUrl;
  final String? videoGuid;

  const VideoSyncScreen({
    super.key,
    required this.matchId,
    required this.videoUrl,
    this.videoGuid,
  });

  @override
  State<VideoSyncScreen> createState() => _VideoSyncScreenState();
}

class _VideoSyncScreenState extends State<VideoSyncScreen> {
  // Controladores
  final BunnyVideoPlayerController _videoController = BunnyVideoPlayerController();

  // Estado
  bool _isLoading = true;
  bool _isSyncing = false;
  int? _kickoffVideoTimestamp; // Segundo del video donde empieza el partido
  int _currentVideoSeconds = 0;
  int _unsyncedEventsCount = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  /// Inicializa la pantalla
  Future<void> _initialize() async {
    try {
      // Contar eventos sin sincronizar
      final result = await Supabase.instance.client
          .rpc('has_unsynced_live_events', params: {'p_match_id': widget.matchId});

      if (result == true) {
        final stats = await Supabase.instance.client
            .rpc('get_live_events_stats', params: {'p_match_id': widget.matchId});

        setState(() {
          _unsyncedEventsCount = stats[0]['unsynced_events'] as int? ?? 0;
        });
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ VideoSyncScreen inicializado: $_unsyncedEventsCount eventos sin sincronizar');
    } catch (e) {
      debugPrint('❌ Error inicializando: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Marca el momento del pitido inicial
  void _markKickoff() {
    setState(() {
      _kickoffVideoTimestamp = _currentVideoSeconds;
    });

    _showInfo('Pitido inicial marcado en ${_formatTime(_currentVideoSeconds)}');
    debugPrint('⚽ Pitido inicial marcado en el segundo: $_currentVideoSeconds');
  }

  /// Ejecuta la sincronización
  Future<void> _syncEvents() async {
    if (_kickoffVideoTimestamp == null) {
      _showError('Primero marca el momento del pitido inicial');
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      // Llamar a la función de sincronización
      final result = await Supabase.instance.client.rpc(
        'sync_live_events_with_video',
        params: {
          'p_match_id': widget.matchId,
          'p_video_offset': _kickoffVideoTimestamp,
        },
      );

      final eventsSync = result[0]['events_synced'] as int;
      final success = result[0]['success'] as bool;
      final message = result[0]['message'] as String;

      if (success) {
        _showSuccess('✅ $message');

        // Volver a la pantalla anterior después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true); // true = sincronización exitosa
        }
      } else {
        _showError(message);
      }

      debugPrint('📊 Sincronización: $eventsSync eventos');
    } catch (e) {
      debugPrint('❌ Error sincronizando: $e');
      _showError('Error al sincronizar eventos');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Formatea segundos a mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Instrucciones
                _buildInstructions(),

                // Video
                Expanded(
                  child: Stack(
                    children: [
                      BunnyVideoPlayer(
                        videoUrl: widget.videoUrl,
                        controller: _videoController,
                        showControls: true,
                        onPositionChanged: (position) {
                          setState(() {
                            _currentVideoSeconds = position.inSeconds;
                          });
                        },
                      ),

                      // Overlay con el botón de marcado
                      if (_kickoffVideoTimestamp == null)
                        Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildMarkKickoffButton(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Panel de confirmación
                if (_kickoffVideoTimestamp != null) _buildConfirmationPanel(),
              ],
            ),
    );
  }

  /// AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        'SINCRONIZAR VIDEO',
        style: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.cyan,
        ),
      ),
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyan),
          const SizedBox(height: 16),
          Text(
            'Analizando eventos...',
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Instrucciones
  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'INSTRUCCIONES',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Reproduce el video y busca el momento exacto del pitido inicial del árbitro.\n'
            '2. Pausa el video justo en ese momento.\n'
            '3. Pulsa "MARCAR PITIDO INICIAL".\n'
            '4. Confirma la sincronización.',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se sincronizarán $_unsyncedEventsCount eventos Live',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botón para marcar el pitido inicial
  Widget _buildMarkKickoffButton() {
    return ElevatedButton.icon(
      onPressed: _markKickoff,
      icon: const Icon(Icons.sports_soccer, size: 32),
      label: Text(
        'MARCAR PITIDO INICIAL',
        style: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.green.withOpacity(0.5),
        elevation: 8,
      ),
    );
  }

  /// Panel de confirmación
  Widget _buildConfirmationPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.0),
            Colors.black,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Información del offset
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pitido Inicial',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatTime(_kickoffVideoTimestamp!),
                      style: GoogleFonts.orbitron(
                        color: Colors.cyan,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Eventos a Sincronizar',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$_unsyncedEventsCount',
                      style: GoogleFonts.orbitron(
                        color: Colors.orange,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              // Cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSyncing
                      ? null
                      : () {
                          setState(() {
                            _kickoffVideoTimestamp = null;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'REINTENTAR',
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Confirmar
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSyncing ? null : _syncEvents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SINCRONIZAR AHORA',
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SNACKBARS
  // ==========================================

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.cyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
