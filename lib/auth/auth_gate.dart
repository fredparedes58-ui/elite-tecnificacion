import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/auth_screen.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/screens/waiting_approval_screen.dart';
import 'package:myapp/widgets/loading_widget.dart';

/// ============================================================
/// AUTH GATE - Detección automática de rol
/// ============================================================
/// Detecta automáticamente el rol del usuario desde Supabase.
/// Una sola transición de estado para evitar parpadeos al cargar.
/// ============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userRole;
  String? _userName;
  bool _isLoading = true;
  String? _error;
  bool? _isApproved;
  bool _detectionDone = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _detectUserRole();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        _detectionDone = false;
        _detectUserRole();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// Detecta el rol del usuario consultando Supabase. Una sola llamada a setState al final.
  Future<void> _detectUserRole() async {
    if (_detectionDone) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        _detectionDone = true;
        setState(() {
          _userRole = null;
          _userName = null;
          _isLoading = false;
        });
        return;
      }

      // Obtener nombre y estado de aprobación desde profiles
      String userName = 'Usuario';
      bool isApproved = true;
      try {
        final profileResponse = await Supabase.instance.client
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
        _isApproved = isApproved;
      } catch (e) {
        debugPrint('Error obteniendo perfil: $e');
      }

      // 1. Verificar si es padre (tiene hijos en parent_child_relationships o rol parent en user_roles)
      bool isParent = false;
      try {
        final childrenResponse = await Supabase.instance.client
            .from('parent_child_relationships')
            .select('id')
            .eq('parent_id', userId)
            .limit(1);
        if (childrenResponse.isNotEmpty) isParent = true;
      } catch (e) {
        debugPrint('Error verificando parent_child_relationships: $e');
      }
      if (!isParent) {
        try {
          final parentRole = await Supabase.instance.client
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
        // 2. Verificar si es admin o coach por usuario (user_roles)
        try {
          final rolesResponse = await Supabase.instance.client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId);
          if (rolesResponse.isNotEmpty) {
            final roles = rolesResponse.map((r) => r['role']?.toString()).whereType<String>().toList();
            resolvedRole = roles.contains('admin') ? 'admin' : (roles.contains('coach') ? 'coach' : null);
          }
        } catch (e) {
          debugPrint('Error verificando user_roles: $e');
        }

        if (resolvedRole == null) {
          try {
            final memberResponse = await Supabase.instance.client
                .from('team_members')
                .select('role')
                .eq('user_id', userId)
                .maybeSingle();
            if (memberResponse != null) {
              final role = memberResponse['role'] as String?;
              if (role != null && ['coach', 'admin'].contains(role)) resolvedRole = role;
            }
          } catch (e) {
            debugPrint('Error verificando team_members: $e');
          }
        }
        resolvedRole ??= 'coach';
      }

      if (!mounted) return;
      _detectionDone = true;
      setState(() {
        _userRole = resolvedRole;
        _userName = userName;
        _isApproved = resolvedApproved;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error detectando rol de usuario: $e');
      if (!mounted) return;
      _detectionDone = true;
      setState(() {
        _error = 'Error detectando rol: $e';
        _userRole = 'coach';
        _userName = 'Usuario';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: const LoadingWidget(message: 'Detectando rol de usuario...'),
        ),
      );
    }

    if (_error != null) {
      debugPrint('⚠️ AuthGate: $_error');
    }

    // Sin usuario autenticado: mostrar login
    if (_userRole == null) {
      return const AuthScreen();
    }

    if (_userRole == 'parent' && _isApproved == false) {
      return const WaitingApprovalScreen();
    }

    return DashboardScreen(
      userRole: _userRole ?? 'coach',
      userName: _userName ?? 'Usuario',
    );
  }
}
