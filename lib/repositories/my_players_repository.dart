// ============================================================
// MyPlayersRepository: jugadores del padre (parent_id = userId).
// Paridad con useMyPlayers en React. Caché + CRUD.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKeyPrefix = 'my_players';
const _cacheTtl = Duration(minutes: 2);

class MyPlayer {
  MyPlayer({
    required this.id,
    required this.parentId,
    required this.name,
    this.birthDate,
    required this.category,
    required this.level,
    this.position,
    this.photoUrl,
    this.stats,
    this.notes,
    this.currentClub,
    this.dominantLeg,
    required this.createdAt,
  });
  final String id;
  final String parentId;
  final String name;
  final String? birthDate;
  final String category;
  final String level;
  final String? position;
  final String? photoUrl;
  final Map<String, int>? stats;
  final String? notes;
  final String? currentClub;
  final String? dominantLeg;
  final DateTime createdAt;
}

class MyPlayersRepository extends ChangeNotifier {
  MyPlayersRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<MyPlayer> _players = [];
  bool _loading = false;
  String? _error;

  List<MyPlayer> get players => List.unmodifiable(_players);
  bool get loading => _loading;
  String? get error => _error;

  static String _cacheKey(String userId) => '$_cacheKeyPrefix:$userId';

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _players = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey(userId));
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
          .select('*')
          .eq('parent_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      _players = list.map(_fromMap).toList();
      _cache.set(_cacheKey(userId), list);
    } catch (e) {
      _error = e.toString();
      _players = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static MyPlayer _fromMap(Map<String, dynamic> m) {
    Map<String, int>? stats;
    if (m['stats'] is Map) {
      stats = (m['stats'] as Map).map((k, v) => MapEntry(k.toString(), (v is int) ? v : int.tryParse(v.toString()) ?? 50));
    }
    return MyPlayer(
      id: m['id']?.toString() ?? '',
      parentId: m['parent_id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      birthDate: m['birth_date']?.toString(),
      category: m['category']?.toString() ?? 'u8',
      level: m['level']?.toString() ?? 'beginner',
      position: m['position']?.toString(),
      photoUrl: m['photo_url']?.toString(),
      stats: stats,
      notes: m['notes']?.toString(),
      currentClub: m['current_club']?.toString(),
      dominantLeg: m['dominant_leg']?.toString(),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  void invalidate() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) _cache.invalidate(_cacheKey(userId));
    notifyListeners();
  }

  Future<MyPlayer?> create({
    required String name,
    String? birthDate,
    required String category,
    String level = 'beginner',
    String? position,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final res = await Supabase.instance.client
          .from('players')
          .insert({
            'parent_id': userId,
            'name': name,
            'birth_date': birthDate,
            'category': category,
            'level': level,
            'position': position,
          })
          .select()
          .single();
      invalidate();
      await fetch(forceRefresh: true);
      return _fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('MyPlayersRepository create: $e');
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await Supabase.instance.client.from('players').update(updates).eq('id', id);
      invalidate();
      await fetch(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('MyPlayersRepository update: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await Supabase.instance.client.from('players').delete().eq('id', id);
      invalidate();
      await fetch(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('MyPlayersRepository delete: $e');
      return false;
    }
  }

  void subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('my-players-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'players',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'parent_id', value: userId),
          callback: (_) => fetch(forceRefresh: true),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
