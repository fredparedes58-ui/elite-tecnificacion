import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// ============================================================
/// WIDGET: BunnyVideoPlayer
/// ============================================================
/// Reproductor de video profesional con controles externos
/// Diseñado específicamente para streaming de Bunny CDN
/// ============================================================

class BunnyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final BunnyVideoPlayerController? controller;
  final bool autoPlay;
  final bool showControls;
  final bool allowFullScreen;
  final VoidCallback? onReady;
  final Function(Duration position)? onPositionChanged;

  const BunnyVideoPlayer({
    super.key,
    required this.videoUrl,
    this.controller,
    this.autoPlay = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.onReady,
    this.onPositionChanged,
  });

  @override
  State<BunnyVideoPlayer> createState() => _BunnyVideoPlayerState();
}

class _BunnyVideoPlayerState extends State<BunnyVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    // Vincular el controlador externo
    if (widget.controller != null) {
      widget.controller!._bindPlayer(this);
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  void didUpdateWidget(BunnyVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayer();
      _initializePlayer();
    }
  }

  /// Inicializa el reproductor de video
  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎥 Inicializando video: ${widget.videoUrl}');

      // Crear controlador de video
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController!.initialize();

      // Crear controlador de Chewie (UI mejorada)
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        allowFullScreen: widget.allowFullScreen,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el video',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // Listener para actualizaciones de posición
      _videoPlayerController!.addListener(() {
        if (widget.onPositionChanged != null) {
          widget.onPositionChanged!(_videoPlayerController!.value.position);
        }
      });

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Video inicializado correctamente');
      widget.onReady?.call();
    } catch (e) {
      debugPrint('❌ Error inicializando video: $e');
    }
  }

  /// Libera recursos del reproductor
  void _disposePlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _isInitialized = false;
  }

  // ==========================================
  // MÉTODOS DE CONTROL INTERNO
  // ==========================================

  Future<void> _play() async {
    await _videoPlayerController?.play();
  }

  Future<void> _pause() async {
    await _videoPlayerController?.pause();
  }

  Future<void> _seekTo(Duration position) async {
    await _videoPlayerController?.seekTo(position);
  }

  Duration? _getCurrentPosition() {
    return _videoPlayerController?.value.position;
  }

  Duration? _getDuration() {
    return _videoPlayerController?.value.duration;
  }

  bool _isPlaying() {
    return _videoPlayerController?.value.isPlaying ?? false;
  }

  double _getVolume() {
    return _videoPlayerController?.value.volume ?? 1.0;
  }

  Future<void> _setVolume(double volume) async {
    await _videoPlayerController?.setVolume(volume.clamp(0.0, 1.0));
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.cyan,
              ),
              SizedBox(height: 16),
              Text(
                'Cargando video...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
}

/// ============================================================
/// CONTROLADOR EXTERNO
/// ============================================================
/// Permite controlar el reproductor desde fuera del widget
/// ============================================================

class BunnyVideoPlayerController {
  _BunnyVideoPlayerState? _playerState;

  /// Vincula el controlador con el widget interno
  void _bindPlayer(_BunnyVideoPlayerState state) {
    _playerState = state;
  }

  /// Reproduce el video
  Future<void> play() async {
    await _playerState?._play();
  }

  /// Pausa el video
  Future<void> pause() async {
    await _playerState?._pause();
  }

  /// Salta a una posición específica
  Future<void> seekTo(Duration position) async {
    await _playerState?._seekTo(position);
  }

  /// Salta a un timestamp en segundos
  Future<void> seekToSeconds(int seconds) async {
    await seekTo(Duration(seconds: seconds));
  }

  /// Obtiene la posición actual
  Duration? getCurrentPosition() {
    return _playerState?._getCurrentPosition();
  }

  /// Obtiene la posición actual en segundos
  int? getCurrentSeconds() {
    return getCurrentPosition()?.inSeconds;
  }

  /// Obtiene la duración total del video
  Duration? getDuration() {
    return _playerState?._getDuration();
  }

  /// Obtiene la duración total en segundos
  int? getDurationSeconds() {
    return getDuration()?.inSeconds;
  }

  /// Verifica si el video está reproduciéndose
  bool isPlaying() {
    return _playerState?._isPlaying() ?? false;
  }

  /// Alterna entre play y pause
  Future<void> togglePlayPause() async {
    if (isPlaying()) {
      await pause();
    } else {
      await play();
    }
  }

  /// Obtiene el volumen actual (0.0 - 1.0)
  double getVolume() {
    return _playerState?._getVolume() ?? 1.0;
  }

  /// Establece el volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _playerState?._setVolume(volume);
  }

  /// Silencia/desilencia el video
  Future<void> toggleMute() async {
    final currentVolume = getVolume();
    if (currentVolume > 0) {
      await setVolume(0.0);
    } else {
      await setVolume(1.0);
    }
  }

  /// Libera el controlador
  void dispose() {
    _playerState = null;
  }
}
