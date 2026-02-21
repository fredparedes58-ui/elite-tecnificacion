// ============================================================
// ReservationsRepository: reservas del usuario (tabla reservations).
// Paridad con useReservations en React. Caché + create/cancel + realtime.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKeyPrefix = 'reservations';
const _cacheTtl = Duration(seconds: 45);

class ReservationItem {
  ReservationItem({
    required this.id,
    required this.userId,
    this.playerId,
    this.trainerId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.creditCost,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String? playerId;
  final String? trainerId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // pending, approved, rejected, etc.
  final int creditCost;
  final DateTime createdAt;
}

class ReservationsRepository extends ChangeNotifier {
  ReservationsRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<ReservationItem> _items = [];
  bool _loading = false;
  String? _error;

  List<ReservationItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  static String _cacheKey(String userId) => '$_cacheKeyPrefix:$userId';

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _items = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey(userId));
      if (cached != null) {
        _items = cached.map(_fromMap).toList();
        notifyListeners();
        return;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('reservations')
          .select('*')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      _items = list.map(_fromMap).toList();
      _cache.set(_cacheKey(userId), list);
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Admin: todas las reservas (sin filtrar por user_id).
  Future<void> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_adminCacheKey);
      if (cached != null) {
        _items = cached.map(_fromMap).toList();
        notifyListeners();
        return;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('reservations')
          .select('*')
          .order('start_time', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      _items = list.map(_fromMap).toList();
      _cache.set(_adminCacheKey, list);
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Admin: actualizar estado de una reserva (ej. approved, rejected).
  Future<bool> updateStatus(String reservationId, String status) async {
    try {
      await Supabase.instance.client
          .from('reservations')
          .update({'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', reservationId);
      invalidate();
      await fetchAll(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('ReservationsRepository updateStatus: $e');
      return false;
    }
  }

  static ReservationItem _fromMap(Map<String, dynamic> m) {
    return ReservationItem(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString() ?? '',
      playerId: m['player_id']?.toString(),
      trainerId: m['trainer_id']?.toString(),
      title: m['title']?.toString() ?? '',
      description: m['description']?.toString(),
      startTime: DateTime.tryParse(m['start_time']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(m['end_time']?.toString() ?? '') ?? DateTime.now(),
      status: m['status']?.toString() ?? 'pending',
      creditCost: (m['credit_cost'] is int) ? m['credit_cost'] as int : int.tryParse(m['credit_cost']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static const _adminCacheKey = 'reservations:all';

  void invalidate() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) _cache.invalidate(_cacheKey(userId));
    _cache.invalidate(_adminCacheKey);
    notifyListeners();
  }

  Future<ReservationItem?> create({
    required String title,
    String? description,
    required String startTime,
    required String endTime,
    String? playerId,
    String? trainerId,
    int creditCost = 1,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final res = await Supabase.instance.client
          .from('reservations')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'start_time': startTime,
            'end_time': endTime,
            'player_id': playerId,
            'trainer_id': trainerId,
            'credit_cost': creditCost,
          })
          .select()
          .single();
      invalidate();
      await fetch(forceRefresh: true);
      return _fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('ReservationsRepository create: $e');
      return null;
    }
  }

  Future<bool> cancel(String id) async {
    try {
      await Supabase.instance.client
          .from('reservations')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      invalidate();
      await fetch(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('ReservationsRepository cancel: $e');
      return false;
    }
  }

  void subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('reservations-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservations',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) => fetch(forceRefresh: true),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
