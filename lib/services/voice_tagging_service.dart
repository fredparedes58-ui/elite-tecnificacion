import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/analysis_event_model.dart';

/// ============================================================
/// SERVICIO: VoiceTaggingService
/// ============================================================
/// Gestiona el reconocimiento de voz para análisis de partidos
/// con auto-detección inteligente de jugadores y eventos
/// ============================================================

class VoiceTaggingService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Cache de jugadores para matching rápido
  List<Player> _teamPlayers = [];

  // Tipos de eventos con keywords
  final Map<String, List<String>> _eventKeywords = {
    'gol': ['gol', 'goal', 'tanto', 'anotación', 'anota'],
    'tiro': ['tiro', 'disparo', 'remate', 'chut', 'patada'],
    'pase': ['pase', 'asistencia', 'habilitación', 'habilita', 'centro'],
    'perdida': ['pérdida', 'perdida', 'pierde', 'error', 'fallo', 'mal'],
    'robo': ['robo', 'recuperación', 'intercepción', 'quite', 'recupera', 'intercepta'],
    'falta': ['falta', 'infracción', 'comete'],
    'corner': ['córner', 'corner', 'esquina', 'tiro de esquina'],
    'tarjeta_amarilla': ['amarilla', 'tarjeta amarilla', 'amonestación'],
    'tarjeta_roja': ['roja', 'tarjeta roja', 'expulsión', 'expulsado'],
    'cambio': ['cambio', 'sustitución', 'relevo', 'sale', 'entra'],
    'lesion': ['lesión', 'lesion', 'dolor', 'herida', 'lastimado'],
  };

  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // ==========================================
  // INICIALIZACIÓN Y PERMISOS
  // ==========================================

  /// Inicializa el servicio de reconocimiento de voz
  Future<bool> initialize() async {
    try {
      // Solicitar permiso de micrófono
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        debugPrint('❌ Permiso de micrófono denegado');
        return false;
      }

      // Inicializar speech-to-text
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('❌ Error STT: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('📊 Estado STT: $status'),
      );

      if (_isInitialized) {
        debugPrint('✅ VoiceTaggingService inicializado correctamente');
      } else {
        debugPrint('❌ No se pudo inicializar STT');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error inicializando VoiceTaggingService: $e');
      return false;
    }
  }

  /// Actualiza la lista de jugadores del equipo para matching
  void setTeamPlayers(List<Player> players) {
    _teamPlayers = players;
    debugPrint('👥 Cache de jugadores actualizado: ${players.length} jugadores');
  }

  // ==========================================
  // RECONOCIMIENTO DE VOZ
  // ==========================================

  /// Inicia la escucha continua de voz
  Future<void> startListening({
    required Function(VoiceTagResult result) onResult,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Servicio no inicializado. Inicializando...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ No se puede iniciar la escucha');
        return;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Ya se está escuchando');
      return;
    }

    try {
      _isListening = true;
      debugPrint('🎤 Iniciando escucha...');

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            debugPrint('📝 Transcripción final: ${result.recognizedWords}');

            // Procesar el resultado
            final voiceResult = _processTranscript(
              result.recognizedWords,
              result.confidence,
            );

            // Notificar al callback
            onResult(voiceResult);
          } else {
            debugPrint('📝 Transcripción parcial: ${result.recognizedWords}');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'es_ES', // Español
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('❌ Error al iniciar escucha: $e');
      _isListening = false;
    }
  }

  /// Detiene la escucha
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Escucha detenida');
    } catch (e) {
      debugPrint('❌ Error al detener escucha: $e');
    }
  }

  /// Cancela la escucha
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      debugPrint('❌ Escucha cancelada');
    } catch (e) {
      debugPrint('❌ Error al cancelar escucha: $e');
    }
  }

  // ==========================================
  // PROCESAMIENTO INTELIGENTE
  // ==========================================

  /// Procesa la transcripción y detecta jugadores/eventos automáticamente
  VoiceTagResult _processTranscript(String transcript, double confidence) {
    final lowerTranscript = transcript.toLowerCase();

    // 1. Detectar tipo de evento
    String? detectedEventType;
    for (final entry in _eventKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerTranscript.contains(keyword.toLowerCase())) {
          detectedEventType = entry.key;
          break;
        }
      }
      if (detectedEventType != null) break;
    }

    // 2. Detectar jugador mencionado
    String? detectedPlayerId;
    String? detectedPlayerName;
    double maxSimilarity = 0.0;

    for (final player in _teamPlayers) {
      // Buscar por nombre completo
      final fullName = player.name.toLowerCase();
      if (lowerTranscript.contains(fullName)) {
        detectedPlayerId = player.id;
        detectedPlayerName = player.name;
        break;
      }

      // Buscar por primer nombre
      final firstName = player.name.split(' ').first.toLowerCase();
      if (lowerTranscript.contains(firstName)) {
        final similarity = _calculateSimilarity(lowerTranscript, firstName);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          detectedPlayerId = player.id;
          detectedPlayerName = player.name;
        }
      }

      // Buscar por apodo si existe
      if (player.nickname != null) {
        final nickname = player.nickname!.toLowerCase();
        if (lowerTranscript.contains(nickname)) {
          detectedPlayerId = player.id;
          detectedPlayerName = player.name;
          break;
        }
      }

      // Buscar por número de camiseta
      if (player.number != null) {
        final numberPattern = RegExp(r'\b${player.number}\b');
        if (numberPattern.hasMatch(lowerTranscript)) {
          detectedPlayerId = player.id;
          detectedPlayerName = player.name;
          break;
        }
      }
    }

    // 3. Generar tags sugeridos
    final suggestedTags = <String>[];
    if (detectedEventType != null) {
      suggestedTags.add(detectedEventType);
    }
    if (lowerTranscript.contains('ataque') || lowerTranscript.contains('ofensiva')) {
      suggestedTags.add('ataque');
    }
    if (lowerTranscript.contains('defensa') || lowerTranscript.contains('defensiva')) {
      suggestedTags.add('defensa');
    }
    if (lowerTranscript.contains('contraataque')) {
      suggestedTags.add('contraataque');
    }
    if (lowerTranscript.contains('táctica') || lowerTranscript.contains('tactica')) {
      suggestedTags.add('táctica');
    }

    // Crear resultado
    final result = VoiceTagResult(
      transcript: transcript,
      confidence: confidence,
      detectedEventType: detectedEventType,
      detectedPlayerId: detectedPlayerId,
      detectedPlayerName: detectedPlayerName,
      suggestedTags: suggestedTags,
    );

    debugPrint('🔍 Análisis completado: $result');
    return result;
  }

  /// Calcula la similitud entre dos strings (simple)
  double _calculateSimilarity(String text, String pattern) {
    if (text.contains(pattern)) return 1.0;

    // Similitud básica por caracteres comunes
    int commonChars = 0;
    for (int i = 0; i < pattern.length; i++) {
      if (text.contains(pattern[i])) commonChars++;
    }
    return commonChars / pattern.length;
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Verifica si los permisos están concedidos
  Future<bool> hasPermissions() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Solicita permisos de micrófono
  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Obtiene los locales disponibles
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    final locales = await _speech.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// Limpia recursos
  void dispose() {
    if (_isListening) {
      stopListening();
    }
    _teamPlayers.clear();
    debugPrint('🧹 VoiceTaggingService limpiado');
  }
}

/// ============================================================
/// SINGLETON GLOBAL
/// ============================================================
/// Para acceso rápido desde cualquier parte de la app
/// ============================================================

final voiceTaggingService = VoiceTaggingService();
