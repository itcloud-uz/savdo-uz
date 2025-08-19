// Autentifikatsiya holatini boshqarish uchun provayder.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savdo_uz/services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  User? get user => _user;
  AuthStatus get status => _status;

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      _user = user;
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      await _authService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
