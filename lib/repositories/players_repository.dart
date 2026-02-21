// ============================================================
// PlayersRepository: listado de todos los jugadores (admin) con padre.
// Paridad con usePlayers + PlayerDirectory / ComparePlayers en React.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'admin_players';
const _cacheTtl = Duration(minutes: 2);

class PlayerWithParent {
  PlayerWithParent({
    required this.id,
    required this.name,
    this.birthDate,
    required this.category,
    required this.level,
    this.position,
    this.photoUrl,
    this.currentClub,
    this.dominantLeg,
    this.stats,
    this.notes,
    required this.parentId,
    this.parentName,
    this.parentEmail,
    this.parentPhone,
  });
  final String id;
  final String name;
  final String? birthDate;
  final String category;
  final String level;
  final String? position;
  final String? photoUrl;
  final String? currentClub;
  final String? dominantLeg;
  final Map<String, int>? stats;
  final String? notes;
  final String parentId;
  final String? parentName;
  final String? parentEmail;
  final String? parentPhone;
}

class PlayersRepository extends ChangeNotifier {
  PlayersRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;

  List<PlayerWithParent> _players = [];
  bool _loading = false;
  String? _error;

  List<PlayerWithParent> get players => List.unmodifiable(_players);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey);
      if (cached != null) {
        _players = cached.map(_fromMap).toList();
        notifyListeners();
        return;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('players')
          .select('id, name, birth_date, position, category, level, current_club, dominant_leg, photo_url, stats, notes, parent_id')
          .order('name');

      final list = List<Map<String, dynamic>>.from(res);
      final parentIds = list.map((p) => p['parent_id']?.toString()).whereType<String>().toSet().toList();

      Map<String, Map<String, dynamic>> parentMap = {};
      if (parentIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, email, phone')
            .inFilter('id', parentIds);
        for (final p in profiles) {
          final id = p['id']?.toString();
          if (id != null) parentMap[id] = Map<String, dynamic>.from(p);
        }
      }

      _players = list.map((p) {
        final pid = p['parent_id']?.toString() ?? '';
        final parent = parentMap[pid];
        return PlayerWithParent(
          id: p['id']?.toString() ?? '',
          name: p['name']?.toString() ?? '',
          birthDate: p['birth_date']?.toString(),
          category: p['category']?.toString() ?? '',
          level: p['level']?.toString() ?? '',
          position: p['position']?.toString(),
          photoUrl: p['photo_url']?.toString(),
          currentClub: p['current_club']?.toString(),
          dominantLeg: p['dominant_leg']?.toString(),
          stats: _parseStats(p['stats']),
          notes: p['notes']?.toString(),
          parentId: pid,
          parentName: parent?['full_name']?.toString(),
          parentEmail: parent?['email']?.toString(),
          parentPhone: parent?['phone']?.toString(),
        );
      }).toList();

      _cache.set(_cacheKey, list.map((p) {
        final pid = p['parent_id']?.toString() ?? '';
        final parent = parentMap[pid];
        return {
          ...p,
          'parent_name': parent?['full_name']?.toString(),
          'parent_email': parent?['email']?.toString(),
          'parent_phone': parent?['phone']?.toString(),
        };
      }).toList());
    } catch (e) {
      _error = e.toString();
      _players = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static Map<String, int>? _parseStats(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0));
    }
    return null;
  }

  static PlayerWithParent _fromMap(Map<String, dynamic> m) {
    return PlayerWithParent(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      birthDate: m['birth_date']?.toString(),
      category: m['category']?.toString() ?? '',
      level: m['level']?.toString() ?? '',
      position: m['position']?.toString(),
      photoUrl: m['photo_url']?.toString(),
      currentClub: m['current_club']?.toString(),
      dominantLeg: m['dominant_leg']?.toString(),
      stats: _parseStats(m['stats']),
      notes: m['notes']?.toString(),
      parentId: m['parent_id']?.toString() ?? '',
      parentName: m['parent_name']?.toString(),
      parentEmail: m['parent_email']?.toString(),
      parentPhone: m['parent_phone']?.toString(),
    );
  }

  void invalidate() {
    _cache.invalidate(_cacheKey);
    notifyListeners();
  }

  PlayerWithParent? getById(String id) {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
