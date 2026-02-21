import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:myapp/auth/auth_gate.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/theme/theme.dart';
import 'package:myapp/screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: ".env");
  
  // Inicializar Supabase con credenciales seguras
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Escuchar cambios en la sesión de autenticación para manejar deep links
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      // Si hay una sesión y el tipo es recovery, navegar a reset password
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // La sesión ya está establecida, solo necesitamos navegar
        // Esto se manejará en el widget
      }
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Verificar si hay una sesión de recuperación de contraseña al iniciar
    _checkPasswordRecovery();
  }

  Future<void> _checkPasswordRecovery() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Verificar si es una sesión de recuperación de contraseña
      // Esto se puede hacer verificando el tipo de token o parámetros en la URL
      // Por ahora, verificamos si hay un access_token en la sesión
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futbol AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      // Manejar rutas para deep linking
      onGenerateRoute: (settings) {
        // Manejar deep link de reset password
        if (settings.name?.startsWith('/reset-password') == true ||
            settings.name?.contains('reset-password') == true) {
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          );
        }
        return null;
      },
    );
  }
}
