// ============================================================
// CreditsRepository: balance de user_credits con caché y realtime.
// Paridad con React useCredits (fetch + realtime + invalidación).
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKeyPrefix = 'credits';
const _balanceTtl = Duration(seconds: 30);

class CreditsRepository extends ChangeNotifier {
  CreditsRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _balanceTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;
  String? _userId;

  int _balance = 0;
  bool _loading = false;
  String? _error;

  int get balance => _balance;
  bool get loading => _loading;
  String? get error => _error;

  /// Clave de caché para un usuario.
  static String _cacheKey(String userId) => '$_cacheKeyPrefix:$userId';

  /// Carga el balance del usuario actual. Usa caché si existe y no expiró.
  Future<int> getBalance({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _balance = 0;
      _error = null;
      notifyListeners();
      return 0;
    }

    if (!forceRefresh) {
      final cached = _cache.get<int>(_cacheKey(userId));
      if (cached != null) {
        _balance = cached;
        _error = null;
        notifyListeners();
        return cached;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('user_credits')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      final value = (res?['balance'] as int?) ?? 0;
      _balance = value;
      _loading = false;
      _error = null;
      _cache.set(_cacheKey(userId), value);
      notifyListeners();
      return value;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Invalida la caché del usuario actual (o de un userId dado).
  void invalidate([String? userId]) {
    final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _cache.invalidate(_cacheKey(uid));
    }
    notifyListeners();
  }

  /// Admin: asigna balance a un usuario (user_credits). Upsert por user_id.
  Future<bool> setBalanceForUser(String targetUserId, int newBalance) async {
    try {
      await Supabase.instance.client.from('user_credits').upsert(
        {'user_id': targetUserId, 'balance': newBalance, 'updated_at': DateTime.now().toUtc().toIso8601String()},
        onConflict: 'user_id',
      );
      invalidate(targetUserId);
      return true;
    } catch (e) {
      debugPrint('CreditsRepository setBalanceForUser: $e');
      return false;
    }
  }

  /// Suscripción realtime para el usuario actual. Actualiza [balance] y caché al cambiar.
  void subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_channel != null && _userId == userId) return;

    _channel?.unsubscribe();
    _userId = userId;

    _channel = Supabase.instance.client
        .channel('user-credits-repo-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_credits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.containsKey('balance')) {
              final b = newRow['balance'] as int?;
              _balance = b ?? 0;
              _cache.set(_cacheKey(userId), _balance);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  /// Deja de escuchar realtime. Llamar en dispose del provider.
  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
    _userId = null;
  }

  /// Historial de transacciones (credit_transactions) para el usuario actual.
  Future<List<CreditTransactionItem>> getTransactionHistory({
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      var query = Supabase.instance.client
          .from('credit_transactions')
          .select('id, amount, transaction_type, description, created_at, reservation_id')
          .eq('user_id', userId);

      if (start != null) {
        query = query.gte('created_at', start.toUtc().toIso8601String());
      }
      if (end != null) {
        query = query.lte('created_at', end.toUtc().toIso8601String());
      }

      final res = await query.order('created_at', ascending: false).limit(limit);
      final list = List<Map<String, dynamic>>.from(res);
      final ids = list.where((r) => r['reservation_id'] != null).map((r) => r['reservation_id'] as String).toSet().toList();
      Map<String, String> sessionTitles = {};
      if (ids.isNotEmpty) {
        final sessions = await Supabase.instance.client
            .from('reservations')
            .select('id, title, start_time')
            .inFilter('id', ids);
        for (final s in sessions) {
          final id = s['id']?.toString();
          if (id != null) {
            final title = s['title']?.toString() ?? 'Sesión';
            final st = s['start_time']?.toString();
            sessionTitles[id] = st != null ? '$title (${DateTime.parse(st).day}/${DateTime.parse(st).month})' : title;
          }
        }
      }

      return list.map((m) {
        final rid = m['reservation_id']?.toString();
        return CreditTransactionItem(
          id: m['id']?.toString() ?? '',
          amount: (m['amount'] is int) ? m['amount'] as int : int.tryParse(m['amount']?.toString() ?? '0') ?? 0,
          transactionType: m['transaction_type']?.toString() ?? '',
          description: m['description']?.toString() ?? sessionTitles[rid] ?? '—',
          createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('CreditsRepository getTransactionHistory: $e');
      return [];
    }
  }
}

class CreditTransactionItem {
  CreditTransactionItem({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdAt,
  });
  final String id;
  final int amount;
  final String transactionType;
  final String description;
  final DateTime createdAt;
}
