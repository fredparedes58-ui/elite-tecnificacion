import 'package:flutter/foundation.dart';

/// Estado de autenticación y rol para el shell de la app.
/// Lo establece el gate (AuthGateRedirect) tras detectar sesión y rol.
class AppAuthState extends ChangeNotifier {
  String? _userId;
  String? _userRole;
  String? _userName;
  bool? _isApproved;

  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;
  bool? get isApproved => _isApproved;

  bool get isAdmin => _userRole == 'admin';
  bool get isParent => _userRole == 'parent';
  bool get isCoach => _userRole == 'coach';
  bool get isLoggedIn => _userId != null;

  void setUser({
    required String userId,
    required String userRole,
    required String userName,
    required bool isApproved,
  }) {
    _userId = userId;
    _userRole = userRole;
    _userName = userName;
    _isApproved = isApproved;
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _userRole = null;
    _userName = null;
    _isApproved = null;
    notifyListeners();
  }
}
