import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        // TUS CLAVES REALES
        url: 'https://bqqjqasqmuyjnvmiuqvl.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxcWpxYXNxbXV5am52bWl1cXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1NzE5MzEsImV4cCI6MjA4MDE0NzkzMX0.pTl7TKI81QXLCY8j0bi2oO9LTbh88VhJXFa5BFG1GTg',
      );
    } catch (e) {
      debugPrint("Error init Supabase: $e");
    }
  }

  SupabaseClient get client => Supabase.instance.client;
}
