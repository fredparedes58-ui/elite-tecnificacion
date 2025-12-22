import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/models/training_session.dart';

class SessionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all training sessions
  Future<List<TrainingSession>> getSessions() async {
    try {
      final response = await _supabase.from('training_sessions').select();
      
      if (response.isEmpty) {
        return [];
      }

      final sessions = response
          .map((data) => TrainingSession.fromMap(data))
          .toList();
      return sessions;
    } catch (e, s) {
      developer.log('Error fetching sessions', error: e, stackTrace: s);
      return [];
    }
  }

  // Add a new training session
  Future<void> addSession(TrainingSession session) async {
    try {
      await _supabase.from('training_sessions').insert(session.toMap());
    } catch (e, s) {
      developer.log('Error adding session', error: e, stackTrace: s);
    }
  }

  // Update a session (e.g., adding/removing drills)
  Future<void> updateSession(TrainingSession session) async {
    try {
      await _supabase
          .from('training_sessions')
          .update(session.toMap())
          .eq('id', session.id);
    } catch (e, s) {
      developer.log('Error updating session', error: e, stackTrace: s);
    }
  }

  // Delete a training session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase.from('training_sessions').delete().eq('id', sessionId);
    } catch (e, s) {
      developer.log('Error deleting session', error: e, stackTrace: s);
    }
  }
}
