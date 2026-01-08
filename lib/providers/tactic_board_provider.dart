
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/tactical_session_model.dart';
import 'package:myapp/models/formation_model.dart';
import 'package:myapp/services/data_service.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TacticBoardProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final DataService _dataService = DataService();
  final SupabaseService _supabaseService = SupabaseService();

  TacticBoardProvider() {
    _initializeData();
  }

  // State
  List<Player> _allPlayers = [];
  List<alignment_model.Alignment> _alignments = [];
  alignment_model.Alignment? _selectedAlignment;
  List<Player> _starters = [];
  List<Player> _substitutes = [];
  Map<String, Offset> _starterPositions = {};
  Offset _ballPosition = const Offset(180, 350);
  bool _isDrawingMode = false;
  List<List<Offset?>> _lines = [];
  List<Offset?> _currentLine = [];
  List<TacticalSession> _sessions = [];
  TacticalSession? _selectedSession;
  final List<Formation> _formations = [];
  bool _isLoading = true;
  
  // Estado para sustituciones
  Player? _selectedPlayerForSubstitution;
  bool _isSubstitutionMode = false;

  // Getters
  bool get isLoading => _isLoading;
  List<Player> get allPlayers => _allPlayers;
  List<alignment_model.Alignment> get alignments => _alignments;
  alignment_model.Alignment? get selectedAlignment => _selectedAlignment;
  List<Player> get starters => _starters;
  List<Player> get substitutes => _substitutes;
  Map<String, Offset> get starterPositions => _starterPositions;
  Offset get ballPosition => _ballPosition;
  bool get isDrawingMode => _isDrawingMode;
  List<List<Offset?>> get lines => _lines;
  List<Offset?> get currentLine => _currentLine;
  List<TacticalSession> get sessions => _sessions;
  TacticalSession? get selectedSession => _selectedSession;
  List<Formation> get formations => _formations;
  Player? get selectedPlayerForSubstitution => _selectedPlayerForSubstitution;
  bool get isSubstitutionMode => _isSubstitutionMode;

  // --- INICIALIZACIÓN ROBUSTA ---
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadPlayersFromSupabase();
      _loadSampleData();
      _autoLoadStartersAndSubs();
    } catch (e, s) {
      developer.log('Error fatal durante la inicialización', error: e, stackTrace: s, name: 'TacticBoardProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga automática de titulares y suplentes según su estado en la base de datos
  void _autoLoadStartersAndSubs() {
    _starters.clear();
    _substitutes.clear();
    _starterPositions.clear();

    // Separar jugadores por estado
    final starterPlayers = _allPlayers.where((p) => p.matchStatus == MatchStatus.starter).toList();
    final subPlayers = _allPlayers.where((p) => p.matchStatus == MatchStatus.sub).toList();

    // Posiciones predeterminadas en formación 4-4-2
    final defaultPositions = [
      const Offset(180, 600),  // Portero
      const Offset(80, 480),   // Defensa 1
      const Offset(140, 500),  // Defensa 2
      const Offset(220, 500),  // Defensa 3
      const Offset(280, 480),  // Defensa 4
      const Offset(80, 340),   // Medio 1
      const Offset(140, 360),  // Medio 2
      const Offset(220, 360),  // Medio 3
      const Offset(280, 340),  // Medio 4
      const Offset(140, 200),  // Delantero 1
      const Offset(220, 200),  // Delantero 2
    ];

    // Colocar titulares en el campo
    for (int i = 0; i < starterPlayers.length && i < 11; i++) {
      _starters.add(starterPlayers[i]);
      _starterPositions[starterPlayers[i].name] = defaultPositions[i];
    }

    // Colocar suplentes en el banquillo
    _substitutes = subPlayers;

    notifyListeners();
  }

  // --- GESTIÓN DE ALINEACIONES Y SESIONES ---
  void selectAlignment(String alignmentId) {
    final selected = _alignments.firstWhere((a) => a.id == alignmentId);
    _selectedAlignment = selected;
    _selectedSession = null; // Anulamos la sesión para evitar conflictos

    _starters.clear();
    _starterPositions.clear();
    _substitutes = List.from(_allPlayers);

    final initialStarters = _allPlayers.where((p) => p.isStarter).take(11).toList();
    for (var player in initialStarters) {
      addStarter(player, Offset(100.0 + (initialStarters.indexOf(player) * 30.0), 150.0 + (initialStarters.indexOf(player) * 20.0)));
    }
    notifyListeners();
  }

  void loadTacticalSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    _selectedSession = session;
    _selectedAlignment = null; // Anulamos la alineación para evitar conflictos

    _starters = List.from(session.starters);
    _substitutes = List.from(session.substitutes);
    _starterPositions = Map.from(session.starterPositions);
    _ballPosition = session.ballPosition;
    _lines = List.from(session.lines.map((line) => List.from(line)));
    notifyListeners();
  }

  void saveTacticalSession(String name) {
    final newSession = TacticalSession(
      id: _uuid.v4(),
      name: name,
      starters: List.from(_starters),
      substitutes: List.from(_substitutes),
      starterPositions: Map.from(_starterPositions),
      ballPosition: _ballPosition,
      lines: List.from(_lines.map((line) => List.from(line))),
    );
    _sessions.add(newSession);
    _selectedSession = newSession;
    notifyListeners();
  }

  // --- GESTIÓN DE FORMACIONES ---
  void saveFormation(String name) {
    final newFormation = Formation(
      id: _uuid.v4(),
      name: name,
      playerPositions: Map.from(_starterPositions),
    );
    _formations.add(newFormation);
    notifyListeners();
  }

  void loadFormation(String formationId) {
    final formation = _formations.firstWhere((f) => f.id == formationId);
    _starterPositions = Map.from(formation.playerPositions);
    notifyListeners();
  }


  // --- GESTIÓN DE JUGADORES ---
  void addStarter(Player player, Offset position) {
    if (!_starters.any((p) => p.name == player.name)) {
      _starters.add(player);
      _substitutes.removeWhere((p) => p.name == player.name);
      _starterPositions[player.name] = position;
      notifyListeners();
    }
  }

  void removeStarter(Player player) {
    if (_starters.any((p) => p.name == player.name)) {
      _starters.remove(player);
      if (!_substitutes.any((sub) => sub.name == player.name)){
        _substitutes.add(player);
      }
      _starterPositions.remove(player.name);
      notifyListeners();
    }
  }

  void updateStarterPosition(Player player, Offset newPosition) {
    if (_starterPositions.containsKey(player.name)) {
      _starterPositions[player.name] = newPosition;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE DIBUJO ---
  void toggleDrawingMode() { _isDrawingMode = !_isDrawingMode; notifyListeners(); }
  void clearDrawing() { _lines.clear(); _currentLine.clear(); notifyListeners(); }
  void onPanStart(Offset position) { if (!_isDrawingMode) return; _currentLine = [position]; notifyListeners(); }
  void onPanUpdate(Offset position) { if (!_isDrawingMode) return; _currentLine.add(position); notifyListeners(); }
  void onPanEnd() { if (!_isDrawingMode) return; _lines.add(List.from(_currentLine)); _currentLine = []; notifyListeners(); }
  void updateBallPosition(Offset newPosition) { _ballPosition = newPosition; notifyListeners(); }

  // --- CARGA DE DATOS ---
  Future<void> _loadPlayers() async {
    final teams = await _dataService.loadTeams();
    _allPlayers = teams.expand((team) => team.players).toList();
  }

  /// Carga jugadores desde Supabase con sus estados de convocatoria
  Future<void> _loadPlayersFromSupabase() async {
    try {
      _allPlayers = await _supabaseService.getTeamPlayers();
      developer.log('Jugadores cargados desde Supabase: ${_allPlayers.length}', name: 'TacticBoardProvider');
    } catch (e, s) {
      developer.log('Error cargando jugadores desde Supabase, usando datos locales', error: e, stackTrace: s, name: 'TacticBoardProvider');
      // Fallback a datos locales si falla Supabase
      await _loadPlayers();
    }
  }

  void _loadSampleData() {
    _alignments = [
      alignment_model.Alignment(id: _uuid.v4(), name: '4-3-3 Ofensivo'),
      alignment_model.Alignment(id: _uuid.v4(), name: '4-4-2 Clásico'),
      alignment_model.Alignment(id: _uuid.v4(), name: '5-4-1 Defensivo'),
      alignment_model.Alignment(id: _uuid.v4(), name: '3-5-2 Moderno'),
    ];

    if (_allPlayers.length >= 2) {
      final sampleStarters = _allPlayers.take(2).toList();
      final sampleSubstitutes = _allPlayers.where((p) => !sampleStarters.contains(p)).toList();

      _sessions = [
        TacticalSession(
          id: _uuid.v4(), 
          name: 'Jugada de Córner', 
          starters: sampleStarters,
          substitutes: sampleSubstitutes,
          starterPositions: {
            sampleStarters[0].name: const Offset(50, 100),
            sampleStarters[1].name: const Offset(150, 200),
          },
          ballPosition: const Offset(50, 50), 
          lines: [
            [const Offset(55, 55), const Offset(100, 120), const Offset(155, 205)]
          ]
        ),
      ];
    }
  }

  // ==========================================
  // SISTEMA DE SUSTITUCIONES
  // ==========================================

  /// Activa el modo de sustitución y selecciona un jugador
  void selectPlayerForSubstitution(Player player) {
    if (_selectedPlayerForSubstitution?.name == player.name) {
      // Si se vuelve a tocar el mismo jugador, se deselecciona
      _selectedPlayerForSubstitution = null;
      _isSubstitutionMode = false;
    } else {
      _selectedPlayerForSubstitution = player;
      _isSubstitutionMode = true;
    }
    notifyListeners();
  }

  /// Realiza el intercambio entre dos jugadores
  Future<void> substitutePlayer(Player targetPlayer) async {
    if (_selectedPlayerForSubstitution == null) return;
    if (_selectedPlayerForSubstitution!.name == targetPlayer.name) return;

    final player1 = _selectedPlayerForSubstitution!;
    final player2 = targetPlayer;

    // Verificar que uno sea titular y otro suplente
    final isPlayer1Starter = _starters.any((p) => p.name == player1.name);
    final isPlayer2Starter = _starters.any((p) => p.name == player2.name);

    if (isPlayer1Starter == isPlayer2Starter) {
      // Ambos son titulares o ambos son suplentes, no se puede hacer el cambio
      developer.log('No se puede sustituir: ambos jugadores tienen el mismo estado', name: 'TacticBoardProvider');
      _selectedPlayerForSubstitution = null;
      _isSubstitutionMode = false;
      notifyListeners();
      return;
    }

    // Determinar quién sale y quién entra
    final playerOut = isPlayer1Starter ? player1 : player2;
    final playerIn = isPlayer1Starter ? player2 : player1;

    // Guardar la posición del jugador que sale
    final savedPosition = _starterPositions[playerOut.name] ?? const Offset(180, 350);

    // Realizar el cambio localmente
    _starters.removeWhere((p) => p.name == playerOut.name);
    _substitutes.removeWhere((p) => p.name == playerIn.name);

    _starters.add(playerIn);
    _substitutes.add(playerOut);

    _starterPositions.remove(playerOut.name);
    _starterPositions[playerIn.name] = savedPosition;

    // Actualizar en Supabase
    if (playerIn.id != null && playerOut.id != null) {
      try {
        await _supabaseService.updatePlayerMatchStatus(
          userId: playerIn.id!,
          matchStatus: 'starter',
        );
        await _supabaseService.updatePlayerMatchStatus(
          userId: playerOut.id!,
          matchStatus: 'sub',
        );
        developer.log('Sustitución actualizada en Supabase: ${playerIn.name} entra por ${playerOut.name}', name: 'TacticBoardProvider');
      } catch (e) {
        developer.log('Error actualizando sustitución en Supabase', error: e, name: 'TacticBoardProvider');
      }
    }

    // Reiniciar el modo de sustitución
    _selectedPlayerForSubstitution = null;
    _isSubstitutionMode = false;
    notifyListeners();
  }

  /// Cancela el modo de sustitución
  void cancelSubstitution() {
    _selectedPlayerForSubstitution = null;
    _isSubstitutionMode = false;
    notifyListeners();
  }

  /// Refresca los jugadores desde la base de datos
  Future<void> refreshPlayers() async {
    _isLoading = true;
    notifyListeners();
    
    await _loadPlayersFromSupabase();
    _autoLoadStartersAndSubs();
    
    _isLoading = false;
    notifyListeners();
  }
}
