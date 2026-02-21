// ============================================================
// ProfileRepository: perfil (nombre, teléfono, avatar). Paridad React Profile.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileData {
  const ProfileData({
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });
  final String fullName;
  final String? phone;
  final String? avatarUrl;
}

class ProfileRepository {
  ProfileRepository() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<ProfileData?> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select('full_name, phone, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return ProfileData(
        fullName: res['full_name']?.toString() ?? '',
        phone: res['phone']?.toString(),
        avatarUrl: res['avatar_url']?.toString(),
      );
    } catch (e) {
      debugPrint('ProfileRepository getProfile: $e');
      return null;
    }
  }

  Future<bool> updateProfile(
    String userId, {
    String? fullName,
    String? phone,
  }) async {
    try {
      final map = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) map['full_name'] = fullName.isEmpty ? null : fullName;
      if (phone != null) map['phone'] = phone.isEmpty ? null : phone;

      await _client.from('profiles').update(map).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('ProfileRepository updateProfile: $e');
      return false;
    }
  }
}
