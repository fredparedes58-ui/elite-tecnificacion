// ============================================================
// InAppNotificationsRepository: tabla notifications (user_id, type, is_read).
// Paridad con useNotificationsCenter en React. Para admin centro de notificaciones.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'in_app_notifications';
const _cacheTtl = Duration(seconds: 60);

class InAppNotification {
  InAppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}

class InAppNotificationsRepository extends ChangeNotifier {
  InAppNotificationsRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<InAppNotification> _items = [];
  bool _loading = false;
  String? _error;

  List<InAppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
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
      final res = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final list = List<Map<String, dynamic>>.from(res);
      _items = list.map(_fromMap).toList();
      _cache.set(_cacheKey, list);
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static InAppNotification _fromMap(Map<String, dynamic> m) {
    return InAppNotification(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString() ?? '',
      type: m['type']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      message: m['message']?.toString() ?? '',
      isRead: m['is_read'] == true,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      metadata: m['metadata'] is Map ? Map<String, dynamic>.from(m['metadata'] as Map) : null,
    );
  }

  Future<bool> markAsRead(String notificationId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
      final i = _items.indexWhere((n) => n.id == notificationId);
      if (i >= 0) {
        _items = List.from(_items);
        _items[i] = InAppNotification(
          id: _items[i].id,
          userId: _items[i].userId,
          type: _items[i].type,
          title: _items[i].title,
          message: _items[i].message,
          isRead: true,
          createdAt: _items[i].createdAt,
          metadata: _items[i].metadata,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('InAppNotificationsRepository markAsRead: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      _items = _items.map((n) => InAppNotification(
        id: n.id,
        userId: n.userId,
        type: n.type,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
        metadata: n.metadata,
      )).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('InAppNotificationsRepository markAllAsRead: $e');
      return false;
    }
  }

  Future<bool> delete(String notificationId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
      _items = _items.where((n) => n.id != notificationId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('InAppNotificationsRepository delete: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);
      _items = [];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('InAppNotificationsRepository clearAll: $e');
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
        .channel('in-app-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
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
