import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/auth/app_auth_state.dart';
import 'package:myapp/repositories/auth_repository.dart';
import 'package:myapp/screens/landing_screen.dart';
import 'package:myapp/screens/waiting_approval_screen.dart';
import 'package:myapp/widgets/loading_widget.dart';

/// Gate que detecta rol y redirige a la ruta correcta (/, /auth, /waiting-approval, /dashboard, /admin).
/// Solo construye contenido cuando no hay sesión (AuthScreen) o padre no aprobado (WaitingApprovalScreen).
/// Si hay sesión y está aprobado, redirige y devuelve un placeholder.
class AuthGateRedirect extends StatefulWidget {
  const AuthGateRedirect({super.key});

  @override
  State<AuthGateRedirect> createState() => _AuthGateRedirectState();
}

class _AuthGateRedirectState extends State<AuthGateRedirect> {
  String? _userRole;
  String? _userName;
  bool _isLoading = true;
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
      } else if (data.event == AuthChangeEvent.signedOut && mounted) {
        Provider.of<AppAuthState>(context, listen: false).clear();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  static final _authRepo = AuthRepository();

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

      final info = await _authRepo.getAuthUserInfo(userId);
      if (info == null) {
        if (!mounted) return;
        _detectionDone = true;
        setState(() {
          _userRole = 'coach';
          _userName = 'Usuario';
          _isLoading = false;
        });
        if (!mounted) return;
        Provider.of<AppAuthState>(context, listen: false).setUser(
          userId: userId,
          userRole: 'coach',
          userName: 'Usuario',
          isApproved: true,
        );
        context.go('/dashboard');
        return;
      }

      if (!mounted) return;
      _detectionDone = true;
      setState(() {
        _userRole = info.role;
        _userName = info.userName;
        _isApproved = info.isApproved;
        _isLoading = false;
      });

      final authState = Provider.of<AppAuthState>(context, listen: false);
      authState.setUser(
        userId: userId,
        userRole: info.role,
        userName: _userName ?? info.userName,
        isApproved: info.isApproved,
      );
      if (info.role == 'parent' && !info.isApproved) {
        context.go('/waiting-approval');
        return;
      }
      if (info.role == 'admin') {
        context.go('/admin');
        return;
      }
      context.go('/dashboard');
    } catch (e) {
      debugPrint('Error detectando rol de usuario: $e');
      if (!mounted) return;
      _detectionDone = true;
      setState(() {
        _userRole = 'coach';
        _userName = 'Usuario';
        _isLoading = false;
      });
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null && mounted) {
        Provider.of<AppAuthState>(context, listen: false).setUser(
          userId: uid,
          userRole: 'coach',
          userName: 'Usuario',
          isApproved: true,
        );
        context.go('/dashboard');
      }
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

    if (_userRole == null) {
      return const LandingScreen();
    }

    if (_userRole == 'parent' && _isApproved == false) {
      return const WaitingApprovalScreen();
    }

    // Redirigir en el siguiente frame si por alguna razón llegamos aquí
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_userRole == 'admin') {
        context.go('/admin');
      } else {
        context.go('/dashboard');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
