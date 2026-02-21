// ============================================================
// NotificationsRepository: avisos (notices) por team y target_roles.
// Paridad con NotificationsScreen actual + useNotifications (realtime opcional).
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'notifications_list';
const _cacheTtl = Duration(seconds: 60);

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.isUrgent,
    this.rawNotice,
  });
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final bool isUrgent;
  final Map<String, dynamic>? rawNotice;
}

class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<NotificationItem> _items = [];
  bool _loading = false;
  String? _error;

  List<NotificationItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _items = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey);
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
      final teamMember = await _client
          .from('team_members')
          .select('team_id, role')
          .eq('user_id', userId)
          .maybeSingle();

      if (teamMember == null) {
        _items = [];
        _loading = false;
        notifyListeners();
        return;
      }

      final teamId = teamMember['team_id'];
      final userRole = teamMember['role']?.toString() ?? '';

      final res = await _client
          .from('notices')
          .select('*, created_by_user:profiles!created_by(full_name)')
          .eq('team_id', teamId)
          .order('created_at', ascending: false)
          .limit(50);

      final notices = List<Map<String, dynamic>>.from(res);
      final targetRoles = (n) {
        final roles = n['target_roles'];
        if (roles == null) return <String>[];
        if (roles is List) return roles.map((e) => e.toString()).toList();
        return [];
      };

      final filtered = notices.where((n) {
        final roles = targetRoles(n);
        return roles.isEmpty || roles.contains(userRole) || roles.contains('all');
      }).toList();

      _items = filtered.map((n) => _toItem(n)).toList();
      _cache.set(_cacheKey, filtered.map((n) => _toCacheMap(n)).toList());
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static NotificationItem _toItem(Map<String, dynamic> n) {
    String author = 'Sistema';
    if (n['created_by_user'] != null && n['created_by_user'] is Map) {
      author = (n['created_by_user'] as Map)['full_name']?.toString() ?? author;
    }
    return NotificationItem(
      id: n['id']?.toString() ?? '',
      title: n['title']?.toString() ?? '',
      content: n['content']?.toString() ?? '',
      author: author,
      createdAt: DateTime.tryParse(n['created_at']?.toString() ?? '') ?? DateTime.now(),
      isUrgent: n['priority'] == 'urgent',
      rawNotice: n,
    );
  }

  static NotificationItem _fromMap(Map<String, dynamic> m) {
    return NotificationItem(
      id: m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      content: m['content']?.toString() ?? '',
      author: m['author']?.toString() ?? 'Sistema',
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      isUrgent: m['is_urgent'] == true,
      rawNotice: m['raw'] is Map ? Map<String, dynamic>.from(m['raw'] as Map) : null,
    );
  }

  static Map<String, dynamic> _toCacheMap(Map<String, dynamic> n) {
    final item = _toItem(n);
    return {
      'id': item.id,
      'title': item.title,
      'content': item.content,
      'author': item.author,
      'created_at': item.createdAt.toIso8601String(),
      'is_urgent': item.isUrgent,
      'raw': item.rawNotice,
    };
  }

  void invalidate() {
    _cache.invalidate(_cacheKey);
    notifyListeners();
  }

  void subscribeRealtime() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications-repo')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notices',
          callback: (_) => fetch(forceRefresh: true),
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }

  SupabaseClient get _client => Supabase.instance.client;
}
