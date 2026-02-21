// ============================================================
// PendingPlayersRepository: jugadores pendientes de aprobación (admin).
// Paridad con usePendingPlayers en React. Caché + realtime.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'pending_players';
const _cacheTtl = Duration(seconds: 60);

class PendingPlayer {
  PendingPlayer({
    required this.id,
    required this.name,
    required this.parentId,
    this.parentName,
    this.category,
    this.position,
    this.photoUrl,
    this.currentClub,
    this.createdAt,
  });
  final String id;
  final String name;
  final String parentId;
  final String? parentName;
  final String? category;
  final String? position;
  final String? photoUrl;
  final String? currentClub;
  final DateTime? createdAt;
}

class PendingPlayersRepository extends ChangeNotifier {
  PendingPlayersRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<PendingPlayer> _players = [];
  bool _loading = false;
  String? _error;

  List<PendingPlayer> get players => List.unmodifiable(_players);
  int get pendingCount => _players.length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchPending({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _players = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey);
      if (cached != null) {
        _players = cached.map((m) => _fromMap(m)).toList();
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
          .select('id, name, parent_id, category, position, photo_url, current_club, created_at')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      final parentIds = list.map((p) => p['parent_id']?.toString()).whereType<String>().toSet().toList();

      Map<String, String> parentNames = {};
      if (parentIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', parentIds);
        for (final p in profiles) {
          final id = p['id']?.toString();
          if (id != null) parentNames[id] = p['full_name']?.toString() ?? '';
        }
      }

      _players = list.map((p) {
        final pid = p['parent_id']?.toString() ?? '';
        return PendingPlayer(
          id: p['id']?.toString() ?? '',
          name: p['name']?.toString() ?? '',
          parentId: pid,
          parentName: parentNames[pid],
          category: p['category']?.toString(),
          position: p['position']?.toString(),
          photoUrl: p['photo_url']?.toString(),
          currentClub: p['current_club']?.toString(),
          createdAt: DateTime.tryParse(p['created_at']?.toString() ?? ''),
        );
      }).toList();

      _cache.set(_cacheKey, list.map((p) => {...p, 'parent_name': parentNames[p['parent_id']?.toString() ?? '']}).toList());
    } catch (e) {
      _error = e.toString();
      _players = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static PendingPlayer _fromMap(Map<String, dynamic> m) {
    return PendingPlayer(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      parentId: m['parent_id']?.toString() ?? '',
      parentName: m['parent_name']?.toString(),
      category: m['category']?.toString(),
      position: m['position']?.toString(),
      photoUrl: m['photo_url']?.toString(),
      currentClub: m['current_club']?.toString(),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
    );
  }

  /// Aprueba un jugador (approval_status = 'approved').
  Future<bool> approve(String playerId) async {
    try {
      await Supabase.instance.client
          .from('players')
          .update({'approval_status': 'approved'})
          .eq('id', playerId);
      invalidate();
      await fetchPending(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('PendingPlayersRepository approve: $e');
      return false;
    }
  }

  /// Rechaza un jugador (approval_status = 'rejected', opcional rejection_reason).
  Future<bool> reject(String playerId, {String? rejectionReason}) async {
    try {
      await Supabase.instance.client
          .from('players')
          .update({
            'approval_status': 'rejected',
            if (rejectionReason != null && rejectionReason.isNotEmpty) 'rejection_reason': rejectionReason,
          })
          .eq('id', playerId);
      invalidate();
      await fetchPending(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('PendingPlayersRepository reject: $e');
      return false;
    }
  }

  void invalidate() {
    _cache.invalidate(_cacheKey);
    notifyListeners();
  }

  void subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('pending-players-repo')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'players',
          callback: (_) => fetchPending(forceRefresh: true),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
