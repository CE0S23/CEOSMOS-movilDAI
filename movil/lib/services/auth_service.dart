import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación con Firebase Auth (email/password).
///
/// Expone registro, login, logout y un stream del usuario actual
/// ([FirebaseAuth.authStateChanges]).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream del usuario autenticado (null cuando no hay sesión).
  Stream<User?> get streamUsuario => _auth.authStateChanges();

  /// Usuario actualmente autenticado (puede ser null).
  User? get usuarioActual => _auth.currentUser;

  /// Crea una cuenta nueva con email y password.
  Future<User> registrar(String email, String password) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credencial.user!;
  }

  /// Inicia sesión con email y password.
  Future<User> iniciarSesion(String email, String password) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credencial.user!;
  }

  /// Cierra la sesión actual.
  Future<void> cerrarSesion() => _auth.signOut();
}