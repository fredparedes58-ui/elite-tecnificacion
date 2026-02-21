// ============================================================
// ConversationsRepository: conversaciones y unread (paridad useConversations).
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'conversations_list';
const _cacheTtl = Duration(seconds: 45);

class ConversationItem {
  ConversationItem({
    required this.id,
    required this.participantId,
    this.subject,
    required this.updatedAt,
    this.participantName,
    this.lastMessagePreview,
    this.unreadCount = 0,
  });
  final String id;
  final String participantId;
  final String? subject;
  final DateTime updatedAt;
  final String? participantName;
  final String? lastMessagePreview;
  final int unreadCount;
}

class ConversationsRepository extends ChangeNotifier {
  ConversationsRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;
  RealtimeChannel? _channel;

  List<ConversationItem> _items = [];
  bool _loading = false;
  String? _error;
  int _totalUnread = 0;

  List<ConversationItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  int get totalUnread => _totalUnread;

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _items = [];
      _totalUnread = 0;
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey);
      if (cached != null) {
        _items = cached.map(_fromMap).toList();
        _totalUnread = _items.fold(0, (s, c) => s + c.unreadCount);
        notifyListeners();
        return;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final roleRes = await Supabase.instance.client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);
      final isAdmin = (roleRes as List).any((r) => r['role'] == 'admin');

      var query = Supabase.instance.client
          .from('conversations')
          .select('*')
          .order('updated_at', ascending: false);
      if (!isAdmin) {
        query = query.eq('participant_id', userId);
      }

      final convos = List<Map<String, dynamic>>.from(await query);

      final unreadRes = await Supabase.instance.client
          .from('conversation_state')
          .select('conversation_id, unread_count')
          .eq('user_id', userId);
      final unreadMap = <String, int>{};
      for (final r in unreadRes as List) {
        final cid = r['conversation_id']?.toString();
        if (cid != null) unreadMap[cid] = (r['unread_count'] is int) ? r['unread_count'] as int : 0;
      }

      final List<ConversationItem> result = [];
      for (final c in convos) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', c['participant_id'])
            .maybeSingle();
        final name = profileRes?['full_name']?.toString();

        final msgRes = await Supabase.instance.client
            .from('messages')
            .select('content')
            .eq('conversation_id', c['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        final preview = msgRes?['content']?.toString();

        result.add(ConversationItem(
          id: c['id']?.toString() ?? '',
          participantId: c['participant_id']?.toString() ?? '',
          subject: c['subject']?.toString(),
          updatedAt: DateTime.tryParse(c['updated_at']?.toString() ?? '') ?? DateTime.now(),
          participantName: name,
          lastMessagePreview: preview,
          unreadCount: unreadMap[c['id']?.toString()] ?? 0,
        ));
      }

      result.sort((a, b) {
        if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
        if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      _items = result;
      _totalUnread = result.fold(0, (s, c) => s + c.unreadCount);
      _cache.set(_cacheKey, result.map(_toMap).toList());
    } catch (e) {
      _error = e.toString();
      _items = [];
      _totalUnread = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static ConversationItem _fromMap(Map<String, dynamic> m) {
    return ConversationItem(
      id: m['id']?.toString() ?? '',
      participantId: m['participant_id']?.toString() ?? '',
      subject: m['subject']?.toString(),
      updatedAt: DateTime.tryParse(m['updated_at']?.toString() ?? '') ?? DateTime.now(),
      participantName: m['participant_name']?.toString(),
      lastMessagePreview: m['last_message_preview']?.toString(),
      unreadCount: (m['unread_count'] is int) ? m['unread_count'] as int : 0,
    );
  }

  static Map<String, dynamic> _toMap(ConversationItem c) {
    return {
      'id': c.id,
      'participant_id': c.participantId,
      'subject': c.subject,
      'updated_at': c.updatedAt.toIso8601String(),
      'participant_name': c.participantName,
      'last_message_preview': c.lastMessagePreview,
      'unread_count': c.unreadCount,
    };
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
        .channel('conversations-repo')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => fetch(forceRefresh: true),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_state',
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
