import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Provider de autenticación: envuelve [AuthService] y expone el estado de
/// sesión como ChangeNotifier para la UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _usuarioActual;
  bool _cargando = false;
  String? _error;
  StreamSubscription<User?>? _authSub;

  User? get usuarioActual => _usuarioActual;
  bool get cargando => _cargando;
  String? get error => _error;

  AuthProvider() {
    _authSub = _authService.streamUsuario.listen((usuario) {
      _usuarioActual = usuario;
      notifyListeners();
    });
  }

  Future<bool> registrar(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registrar(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _traducirError(e);
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> iniciarSesion(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.iniciarSesion(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _traducirError(e);
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    _error = null;
    await _authService.cerrarSesion();
  }

  String _traducirError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-disabled':
        return 'La cuenta está deshabilitada';
      case 'user-not-found':
        return 'No existe una cuenta con ese email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email';
      case 'weak-password':
        return 'La contraseña es muy débil (mín. 6 caracteres)';
      case 'too-many-requests':
        return 'Demasiados intentos, espera un momento';
      default:
        return e.message ?? 'Error de autenticación';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}