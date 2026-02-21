// ============================================================
// AuthRepository: perfil y resolución de rol (paridad AuthContext React).
// Centraliza fetch de profiles, user_roles, parent_child, team_members.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUserInfo {
  const AuthUserInfo({
    required this.userName,
    required this.isApproved,
    required this.role,
  });
  final String userName;
  final bool isApproved;
  final String role; // 'parent' | 'admin' | 'coach'
}

class AuthRepository {
  AuthRepository() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Resuelve perfil (nombre, aprobación) y rol (parent / admin / coach).
  /// Misma lógica que AuthContext + AuthGate en React/Flutter.
  Future<AuthUserInfo?> getAuthUserInfo(String userId) async {
    try {
      String userName = 'Usuario';
      bool isApproved = true;
      final profileResponse = await _client
          .from('profiles')
          .select('full_name, is_approved')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null) {
        if (profileResponse['full_name'] != null) {
          userName = profileResponse['full_name'] as String;
        }
        if (profileResponse['is_approved'] != null) {
          isApproved = profileResponse['is_approved'] as bool;
        }
      }

      bool isParent = false;
      try {
        final childrenResponse = await _client
            .from('parent_child_relationships')
            .select('id')
            .eq('parent_id', userId)
            .limit(1);
        if (childrenResponse.isNotEmpty) isParent = true;
      } catch (e) {
        debugPrint('AuthRepository parent_child: $e');
      }
      if (!isParent) {
        try {
          final parentRole = await _client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId)
              .eq('role', 'parent')
              .maybeSingle();
          if (parentRole != null) isParent = true;
        } catch (_) {}
      }

      String? resolvedRole;
      bool? resolvedApproved = isApproved;

      if (isParent && !isApproved) {
        resolvedRole = 'parent';
        resolvedApproved = false;
      } else if (isParent) {
        resolvedRole = 'parent';
      } else {
        try {
          final rolesResponse = await _client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId);
          if (rolesResponse.isNotEmpty) {
            final roles = rolesResponse.map((r) => r['role']?.toString()).whereType<String>().toList();
            resolvedRole = roles.contains('admin') ? 'admin' : (roles.contains('coach') ? 'coach' : null);
          }
        } catch (e) {
          debugPrint('AuthRepository user_roles: $e');
        }

        if (resolvedRole == null) {
          try {
            final memberResponse = await _client
                .from('team_members')
                .select('role')
                .eq('user_id', userId)
                .maybeSingle();
            if (memberResponse != null) {
              final role = memberResponse['role'] as String?;
              if (role != null && ['coach', 'admin'].contains(role)) resolvedRole = role;
            }
          } catch (e) {
            debugPrint('AuthRepository team_members: $e');
          }
        }
        resolvedRole ??= 'coach';
      }

      return AuthUserInfo(
        userName: userName,
        isApproved: resolvedApproved ?? true,
        role: resolvedRole ?? 'coach',
      );
    } catch (e) {
      debugPrint('AuthRepository getAuthUserInfo: $e');
      return null;
    }
  }
}
