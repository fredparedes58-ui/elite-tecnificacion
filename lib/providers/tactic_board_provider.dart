
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/models/alignment_model.dart' as alignment_model;
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/tactical_session_model.dart';
import 'package:myapp/models/formation_model.dart';
import 'package:myapp/services/data_service.dart';
import 'package:uuid/uuid.dart';

class TacticBoardProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final DataService _dataService = DataService();

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

  // --- INICIALIZACIÓN ROBUSTA ---
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadPlayers();
      _loadSampleData();
      if (_alignments.isNotEmpty) {
        selectAlignment(_alignments.first.id);
      }
    } catch (e, s) {
      developer.log('Error fatal durante la inicialización', error: e, stackTrace: s, name: 'TacticBoardProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  void _loadSampleData() {
    _alignments = [
      alignment_model.Alignment(id: _uuid.v4(), name: '4-3-3 Ofensivo'),
      alignment_model.Alignment(id: _uuid.v4(), name: '5-4-1 Defensivo'),
    ];

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
