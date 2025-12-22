import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myapp/auth/auth_gate.dart';
import 'package:myapp/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await Supabase.initialize(
    url: 'https://jiryulsoxghgunvcewruua.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imppcnl1bHNveGhndW52Y2V3cnV1YSIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzE2NDg5ODc5LCJleHAiOjIwMzIwNjU4Nzl9.gF-rC9L9-G2n2o_2s-I-a8h1z_2C-p-Q3e-N5i-O6U0',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppTheme(),
      child: Consumer<AppTheme>(
        builder: (context, appTheme, _) {
          return MaterialApp(
            title: 'Futbol AI',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appTheme.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
