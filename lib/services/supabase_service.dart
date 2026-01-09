import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/models/chat_message_model.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Error init Supabase: $e");
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  // ============================================================
  // TEAM MANAGEMENT
  // ============================================================

  Future<List<Map<String, dynamic>>> getTeamPlayers(String teamId) async {
    try {
      final response = await client
          .from('team_members')
          .select('*, profiles(*)')
          .eq('team_id', teamId)
          .eq('role', 'player');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting team players: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      final response = await client.from('teams').select('*');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting all teams: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .ilike('full_name', '%$query%');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  Future<bool> addUserToTeam(String userId, String teamId, String role) async {
    try {
      await client.from('team_members').insert({
        'user_id': userId,
        'team_id': teamId,
        'role': role,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding user to team: $e');
      return false;
    }
  }

  Future<Map<String, int>> getPlayersCountByStatus(String teamId) async {
    try {
      final response = await client
          .from('players')
          .select('match_status')
          .eq('team_id', teamId);

      final data = List<Map<String, dynamic>>.from(response);
      final counts = {'available': 0, 'injured': 0, 'suspended': 0};

      for (var player in data) {
        final status = player['match_status'] ?? 'available';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting players count by status: $e');
      return {'available': 0, 'injured': 0, 'suspended': 0};
    }
  }

  Future<bool> updatePlayerMatchStatus(String playerId, String status) async {
    try {
      await client
          .from('players')
          .update({'match_status': status})
          .eq('id', playerId);
      return true;
    } catch (e) {
      debugPrint('Error updating player match status: $e');
      return false;
    }
  }

  // ============================================================
  // ATTENDANCE SYSTEM
  // ============================================================

  Future<Map<String, dynamic>?> getTrainingSessionByDate(
    String teamId,
    DateTime date,
  ) async {
    try {
      final response = await client
          .from('training_sessions')
          .select('*')
          .eq('team_id', teamId)
          .gte('session_date', date.toIso8601String().split('T')[0])
          .lt(
            'session_date',
            date.add(Duration(days: 1)).toIso8601String().split('T')[0],
          )
          .single();
      return response;
    } catch (e) {
      debugPrint('Error getting training session: $e');
      return null;
    }
  }

  Future<String> createTrainingSession({
    required String teamId,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await client
          .from('training_sessions')
          .insert({
            'team_id': teamId,
            'session_date': date.toIso8601String(),
            'notes': notes,
          })
          .select()
          .single();
      return response['id'];
    } catch (e) {
      debugPrint('Error creating training session: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecords(
    String sessionId,
  ) async {
    try {
      final response = await client
          .from('attendance_records')
          .select('*')
          .eq('session_id', sessionId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting attendance records: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecordsWithMarker(
    String sessionId,
  ) async {
    try {
      final response = await client
          .from('attendance_records')
          .select('*, marked_by_user:profiles!marked_by(full_name)')
          .eq('session_id', sessionId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting attendance records with marker: $e');
      return [];
    }
  }

  Future<bool> saveAttendanceRecords(
    String sessionId,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      // Delete existing records
      await client
          .from('attendance_records')
          .delete()
          .eq('session_id', sessionId);

      // Insert new records
      await client.from('attendance_records').insert(records);
      return true;
    } catch (e) {
      debugPrint('Error saving attendance records: $e');
      return false;
    }
  }

  Future<double> getAttendanceRate(String playerId) async {
    try {
      final totalResponse = await client
          .from('attendance_records')
          .select('id')
          .eq('player_id', playerId);

      final presentResponse = await client
          .from('attendance_records')
          .select('id')
          .eq('player_id', playerId)
          .eq('status', 'present');

      final total = (totalResponse as List).length;
      final present = (presentResponse as List).length;

      if (total == 0) return 0.0;
      return (present / total) * 100;
    } catch (e) {
      debugPrint('Error getting attendance rate: $e');
      return 0.0;
    }
  }

  // ============================================================
  // PARENT ATTENDANCE
  // ============================================================

  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    try {
      final response = await client
          .from('parent_children')
          .select('*, child:profiles!child_id(*)')
          .eq('parent_id', parentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting parent children: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getParentTrainingSessions(
    String childId,
  ) async {
    try {
      final response = await client
          .from('training_sessions')
          .select('*')
          .gte('session_date', DateTime.now().toIso8601String())
          .order('session_date');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting parent training sessions: $e');
      return [];
    }
  }

  Future<bool> markChildAttendance({
    required String sessionId,
    required String playerId,
    required String status,
    String? notes,
  }) async {
    try {
      await client.from('attendance_records').insert({
        'session_id': sessionId,
        'player_id': playerId,
        'status': status,
        'notes': notes,
        'marked_by': client.auth.currentUser?.id,
      });
      return true;
    } catch (e) {
      debugPrint('Error marking child attendance: $e');
      return false;
    }
  }

  // ============================================================
  // CHAT SYSTEM
  // ============================================================

  Future<void> ensureDefaultChannels(String teamId) async {
    try {
      final channels = [
        {'name': 'General', 'icon': 'chat'},
        {'name': 'Entrenadores', 'icon': 'sports'},
        {'name': 'Padres', 'icon': 'family_restroom'},
      ];

      for (var channel in channels) {
        await client.from('chat_channels').upsert({
          'team_id': teamId,
          'name': channel['name'],
          'icon': channel['icon'],
        });
      }
    } catch (e) {
      debugPrint('Error ensuring default channels: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeamChatChannels(String teamId) async {
    try {
      final response = await client
          .from('chat_channels')
          .select('*')
          .eq('team_id', teamId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting team chat channels: $e');
      return [];
    }
  }

  Future<bool?> sendMessage(CreateChatMessageDto message) async {
    try {
      await client.from('chat_messages').insert({
        'channel_id': message.channelId,
        'user_id': client.auth.currentUser?.id,
        'content': message.content,
        'media_url': message.mediaUrl,
        'media_type': message.mediaType?.value,
      });
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  Stream<List<ChatMessage>> streamChannelMessages(String channelId) {
    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at')
        .map(
          (data) => (data as List)
              .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
  }

  // ============================================================
  // NOTICE BOARD
  // ============================================================

  Future<String> createNotice({
    required String teamId,
    required String title,
    required String content,
    required String priority,
    required List<String> targetRoles,
    String? attachmentUrl,
  }) async {
    try {
      final response = await client
          .from('notices')
          .insert({
            'team_id': teamId,
            'title': title,
            'content': content,
            'priority': priority,
            'target_roles': targetRoles,
            'attachment_url': attachmentUrl,
            'created_by': client.auth.currentUser?.id,
          })
          .select()
          .single();
      return response['id'];
    } catch (e) {
      debugPrint('Error creating notice: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNoticeReadStats(String noticeId) async {
    try {
      final totalResponse = await client
          .from('notice_reads')
          .select('id')
          .eq('notice_id', noticeId);

      final readResponse = await client
          .from('notice_reads')
          .select('id')
          .eq('notice_id', noticeId)
          .eq('is_read', true);

      final total = (totalResponse as List).length;
      final read = (readResponse as List).length;

      return {'total': total, 'read': read, 'unread': total - read};
    } catch (e) {
      debugPrint('Error getting notice read stats: $e');
      return {'total': 0, 'read': 0, 'unread': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadUsers(String noticeId) async {
    try {
      final response = await client
          .from('notice_reads')
          .select('*, user:profiles(*)')
          .eq('notice_id', noticeId)
          .eq('is_read', false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting unread users: $e');
      return [];
    }
  }

  // ============================================================
  // TACTICAL BOARD & ALIGNMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAlignments(String teamId) async {
    try {
      final response = await client
          .from('alignments')
          .select('*')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting alignments: $e');
      return [];
    }
  }

  Future<String> saveAlignment(Map<String, dynamic> alignment) async {
    try {
      final response = await client
          .from('alignments')
          .insert(alignment)
          .select()
          .single();
      return response['id'];
    } catch (e) {
      debugPrint('Error saving alignment: $e');
      rethrow;
    }
  }

  Future<bool> deleteAlignment(String alignmentId) async {
    try {
      await client.from('alignments').delete().eq('id', alignmentId);
      return true;
    } catch (e) {
      debugPrint('Error deleting alignment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTacticalSessionVideos(
    String sessionId,
  ) async {
    try {
      final response = await client
          .from('tactical_videos')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting tactical session videos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAlignmentVideos(
    String alignmentId,
  ) async {
    try {
      final response = await client
          .from('tactical_videos')
          .select('*')
          .eq('alignment_id', alignmentId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting alignment videos: $e');
      return [];
    }
  }

  Future<String> uploadTacticalVideo({
    required File videoFile,
    required String teamId,
    String? sessionId,
    String? alignmentId,
    String? title,
    String? description,
  }) async {
    try {
      // Upload video to storage
      final fileName = 'tactical_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = '$teamId/tactical/$fileName';

      await client.storage.from('videos').upload(path, videoFile);

      final videoUrl = client.storage.from('videos').getPublicUrl(path);

      // Save video metadata
      final response = await client
          .from('tactical_videos')
          .insert({
            'team_id': teamId,
            'session_id': sessionId,
            'alignment_id': alignmentId,
            'title': title,
            'description': description,
            'video_url': videoUrl,
            'uploaded_by': client.auth.currentUser?.id,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      debugPrint('Error uploading tactical video: $e');
      rethrow;
    }
  }

  /// Guarda los metadatos de un video táctico después de subir a Bunny Stream
  Future<Map<String, dynamic>?> saveTacticalVideoMetadata({
    required String teamId,
    String? tacticalSessionId,
    String? alignmentId,
    required String videoUrl,
    required String videoGuid,
    String? thumbnailUrl,
    required String title,
    String? description,
    String? videoType,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await client
          .from('tactical_videos')
          .insert({
            'team_id': teamId,
            'coach_id': userId,
            'tactical_session_id': tacticalSessionId,
            'alignment_id': alignmentId,
            'video_url': videoUrl,
            'video_guid': videoGuid,
            'thumbnail_url': thumbnailUrl,
            'title': title,
            'description': description,
            'video_type': videoType ?? 'reference',
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error saving tactical video metadata: $e');
      return null;
    }
  }

  Future<bool> deleteTacticalVideo(String videoId) async {
    try {
      // Get video info
      final video = await client
          .from('tactical_videos')
          .select('video_url')
          .eq('id', videoId)
          .single();

      // Delete from storage
      final url = video['video_url'] as String;
      final path = url.split('/').last;
      await client.storage.from('videos').remove([path]);

      // Delete record
      await client.from('tactical_videos').delete().eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error deleting tactical video: $e');
      return false;
    }
  }

  // ============================================================
  // PLAYER ANALYSIS VIDEOS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPlayerAnalysisVideos(
    String playerId,
  ) async {
    try {
      final response = await client
          .from('player_analysis_videos')
          .select('*')
          .eq('player_id', playerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting player analysis videos: $e');
      return [];
    }
  }

  Future<String> uploadPlayerAnalysisVideo({
    required File videoFile,
    required String playerId,
    required String teamId,
    String? title,
    String? description,
    String? category,
  }) async {
    try {
      // Upload video to storage
      final fileName =
          'analysis_${playerId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = '$teamId/analysis/$fileName';

      await client.storage.from('videos').upload(path, videoFile);

      final videoUrl = client.storage.from('videos').getPublicUrl(path);

      // Save video metadata
      final response = await client
          .from('player_analysis_videos')
          .insert({
            'player_id': playerId,
            'team_id': teamId,
            'title': title,
            'description': description,
            'category': category,
            'video_url': videoUrl,
            'uploaded_by': client.auth.currentUser?.id,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      debugPrint('Error uploading player analysis video: $e');
      rethrow;
    }
  }

  /// Guarda los metadatos de un video de análisis después de subir a Bunny Stream
  Future<Map<String, dynamic>?> savePlayerAnalysisVideoMetadata({
    required String playerId,
    required String teamId,
    required String videoUrl,
    required String videoGuid,
    String? thumbnailUrl,
    required String title,
    String? comments,
    String? analysisType,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await client
          .from('player_analysis_videos')
          .insert({
            'player_id': playerId,
            'coach_id': userId,
            'team_id': teamId,
            'video_url': videoUrl,
            'video_guid': videoGuid,
            'thumbnail_url': thumbnailUrl,
            'title': title,
            'comments': comments,
            'analysis_type': analysisType,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error saving player analysis video metadata: $e');
      return null;
    }
  }

  Future<bool> deletePlayerAnalysisVideo(String videoId) async {
    try {
      // Get video info
      final video = await client
          .from('player_analysis_videos')
          .select('video_url')
          .eq('id', videoId)
          .single();

      // Delete from storage
      final url = video['video_url'] as String;
      final path = url.split('/').last;
      await client.storage.from('videos').remove([path]);

      // Delete record
      await client.from('player_analysis_videos').delete().eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error deleting player analysis video: $e');
      return false;
    }
  }

  // ============================================================
  // PROMATCH ANALYSIS
  // ============================================================

  Future<bool> hasUnsyncedLiveEvents(String matchId) async {
    try {
      final response = await client
          .from('live_match_events')
          .select('id')
          .eq('match_id', matchId)
          .eq('synced', false);
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking unsynced live events: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getLiveEventsStats(String matchId) async {
    try {
      final events = await client
          .from('live_match_events')
          .select('event_type')
          .eq('match_id', matchId);

      final data = List<Map<String, dynamic>>.from(events);
      final stats = <String, int>{};

      for (var event in data) {
        final type = event['event_type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting live events stats: $e');
      return {};
    }
  }
}
