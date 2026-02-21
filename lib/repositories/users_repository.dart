// ============================================================
// UsersRepository: listado de usuarios (admin) con roles y créditos.
// Paridad con useUsers en React. Aprobar/revocar y ver créditos.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/memory_cache.dart';

const _cacheKey = 'admin_users';
const _cacheTtl = Duration(seconds: 90);

class UserProfileItem {
  UserProfileItem({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    required this.isApproved,
    required this.createdAt,
    required this.role,
    required this.credits,
  });
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final bool isApproved;
  final DateTime createdAt;
  final String role; // 'admin' | 'coach' | 'parent'
  final int credits;
}

class UsersRepository extends ChangeNotifier {
  UsersRepository({MemoryCache? cache})
      : _cache = cache ?? MemoryCache(defaultTtl: _cacheTtl);

  final MemoryCache _cache;

  List<UserProfileItem> _users = [];
  bool _loading = false;
  String? _error;

  List<UserProfileItem> get users => List.unmodifiable(_users);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch({bool forceRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _users = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(_cacheKey);
      if (cached != null) {
        _users = cached.map(_fromMap).toList();
        notifyListeners();
        return;
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      final usersWithDetails = <UserProfileItem>[];

      for (final p in list) {
        final uid = p['id']?.toString() ?? '';
        final rolesRes = await Supabase.instance.client
            .from('user_roles')
            .select('role')
            .eq('user_id', uid);
        final rolesList = List<dynamic>.from(rolesRes as List);
        final firstRole = rolesList.isNotEmpty ? rolesList[0] : null;
        final role = (firstRole is Map<String, dynamic>)
            ? (firstRole['role']?.toString() ?? 'parent')
            : 'parent';

        final creditsRes = await Supabase.instance.client
            .from('user_credits')
            .select('balance')
            .eq('user_id', uid)
            .maybeSingle();
        final creditsMap = creditsRes is Map<String, dynamic> ? creditsRes : null;
        final credits = (creditsMap != null && creditsMap['balance'] != null)
            ? (creditsMap['balance'] is int
                ? creditsMap['balance'] as int
                : int.tryParse(creditsMap['balance']?.toString() ?? '0') ?? 0)
            : 0;

        usersWithDetails.add(UserProfileItem(
          id: uid,
          email: p['email']?.toString() ?? '',
          fullName: p['full_name']?.toString(),
          avatarUrl: p['avatar_url']?.toString(),
          phone: p['phone']?.toString(),
          isApproved: p['is_approved'] == true,
          createdAt: DateTime.tryParse(p['created_at']?.toString() ?? '') ?? DateTime.now(),
          role: role,
          credits: credits,
        ));
      }

      _users = usersWithDetails;
      _cache.set(_cacheKey, list);
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static UserProfileItem _fromMap(Map<String, dynamic> m) {
    return UserProfileItem(
      id: m['id']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      fullName: m['full_name']?.toString(),
      avatarUrl: m['avatar_url']?.toString(),
      phone: m['phone']?.toString(),
      isApproved: m['is_approved'] == true,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      role: m['role']?.toString() ?? 'parent',
      credits: (m['credits'] is int) ? m['credits'] as int : int.tryParse(m['credits']?.toString() ?? '0') ?? 0,
    );
  }

  Future<bool> updateApproval(String userId, bool isApproved) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_approved': isApproved, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
      invalidate();
      await fetch(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('UsersRepository updateApproval: $e');
      return false;
    }
  }

  void invalidate() {
    _cache.invalidate(_cacheKey);
    notifyListeners();
  }
}
