import 'package:flutter/material.dart';
import 'package:myapp/screens/dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Se omite la comprobación de sesión y se va directamente al Dashboard.
    return const DashboardScreen(userRole: 'coach', userName: 'Coach');
  }
}
