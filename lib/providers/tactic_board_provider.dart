import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/player_model.dart';
import '../models/alignment_model.dart' as alignment_model;

class TacticBoardProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  TacticBoardProvider() {
    _initializeData();
  }

  final List<Player> _allPlayers = [];
  List<alignment_model.Alignment> _alignments = [];
  alignment_model.Alignment? _selectedAlignment;

  final List<Player> _starters = [];
  List<Player> _substitutes = [];
  final Map<String, Offset> _starterPositions = {};

  bool _isLoading = true;
  bool _isSaving = false;
  final bool _isCoach = true;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isCoach => _isCoach;
  List<Player> get allPlayers => _allPlayers;
  List<alignment_model.Alignment> get alignments => _alignments;
  alignment_model.Alignment? get selectedAlignment => _selectedAlignment;
  List<Player> get starters => _starters;
  List<Player> get substitutes => _substitutes;
  Map<String, Offset> get starterPositions => _starterPositions;

  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    await _loadPlayersFromCsv();
    _loadSampleAlignments();

    if (_alignments.isNotEmpty) {
      selectAlignment(_alignments.first.id);
    } else {
      createNewAlignment('4-3-3 Clásico');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPlayersFromCsv() async {
    final rawData = await rootBundle.loadString('assets/data/players.csv');
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData, eol: '\n');
    
    _allPlayers.clear();

    // Skip header row
    for (var i = 1; i < listData.length; i++) {
      final row = listData[i];
      try {
          final player = Player(
          name: row[0].toString(),
          number: row[1].toString(),
          level: int.parse(row[2].toString()),
          position1: row[3].toString(),
          position2: row[4].toString(),
          avatarAsset: row[5].toString(),
          stats: PlayerStats(
            media: int.parse(row[6].toString()),
            pac: int.parse(row[7].toString()),
            sho: int.parse(row[8].toString()),
            pas: int.parse(row[9].toString()),
            dri: int.parse(row[10].toString()),
            def: int.parse(row[11].toString()),
            phy: int.parse(row[12].toString()),
            goals: int.parse(row[13].toString()),
            asst: int.parse(row[14].toString()),
          ),
        );
        _allPlayers.add(player);
      } catch (e) {
        print('Error parsing row $i: $row. Error: $e');
      }
    }
  }

  void _loadSampleAlignments() {
    final alignment1 = alignment_model.Alignment(
      id: _uuid.v4(),
      name: '4-3-3 Ofensivo',
    );
    final alignment2 = alignment_model.Alignment(
      id: _uuid.v4(),
      name: '5-4-1 Defensivo',
    );
    _alignments = [alignment1, alignment2];
  }

  void selectAlignment(String alignmentId) {
    final selected = _alignments.firstWhere((a) => a.id == alignmentId);
    _selectedAlignment = selected;

    _starters.clear();
    _starterPositions.clear();
    _substitutes = List.from(_allPlayers);

    if (selected.name == '4-3-3 Ofensivo' && _allPlayers.length >= 11) {
      for (int i = 0; i < 11; i++) {
        final player = _allPlayers[i];
        _starters.add(player);
        _substitutes.remove(player);
        _starterPositions[player.name] = Offset(
          100.0 + (i * 20),
          150.0 + (i * 10),
        );
      }
    }

    notifyListeners();
  }

  void createNewAlignment(String name) {
    final newAlignment = alignment_model.Alignment(id: _uuid.v4(), name: name);
    _alignments.add(newAlignment);
    selectAlignment(newAlignment.id);
    notifyListeners();
  }

  Future<void> saveCurrentAlignment() async {
    _isSaving = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isSaving = false;
    notifyListeners();
  }

  void addStarter(Player player, Offset position) {
    if (!_starters.contains(player)) {
      _starters.add(player);
      _substitutes.remove(player);
      _starterPositions[player.name] = position;
      notifyListeners();
    }
  }

  void removeStarter(Player player) {
    if (_starters.contains(player)) {
      _starters.remove(player);
      if (!_substitutes.any((p) => p.name == player.name)) {
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

  void addPlayer(String name, String position1) {
    final newPlayer = Player(
      name: name,
      number: '99',
      level: 1,
      position1: position1,
      position2: 'N/A',
      avatarAsset: 'assets/players/default.png',
      stats: PlayerStats(media: 1, pac: 1, sho: 1, pas: 1, dri: 1, def: 1, phy: 1, goals: 1, asst: 1),
    );
    _allPlayers.add(newPlayer);
    _substitutes.add(newPlayer);
    notifyListeners();
  }

  void removePlayer(Player player) {
    _allPlayers.removeWhere((p) => p.name == player.name);
    _starters.removeWhere((p) => p.name == player.name);
    _substitutes.removeWhere((p) => p.name == player.name);
    _starterPositions.remove(player.name);
    notifyListeners();
  }
}
