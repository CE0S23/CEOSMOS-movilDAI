import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/favorito_model.dart';
import '../models/historial_model.dart';
import '../services/firestore_service.dart';

/// Provee historial de sesiones terminadas y la lista de favoritos del
/// usuario autenticado, sincronizados en tiempo real con Firestore bajo
/// `usuarios/{uid}/historial` y `usuarios/{uid}/favoritos`.
class HistorialProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<HistorialModel> _historial = [];
  List<FavoritoModel> _favoritos = [];
  String? _uid;
  bool _uidInicializado = false;

  StreamSubscription<List<HistorialModel>>? _histSub;
  StreamSubscription<List<FavoritoModel>>? _favSub;

  List<HistorialModel> get historial => _historial;
  List<FavoritoModel> get favoritos => _favoritos;
  String? get uid => _uid;

  /// Vincula el provider al usuario autenticado; re-suscribe los streams de
  /// historial y favoritos cuando el uid cambia (o los limpia si es null).
  void setUid(String? uid) {
    if (_uidInicializado && _uid == uid) {
      return;
    }
    _uidInicializado = true;
    _uid = uid;

    _histSub?.cancel();
    _favSub?.cancel();
    _histSub = null;
    _favSub = null;
    _historial = [];
    _favoritos = [];

    if (uid == null) {
      notifyListeners();
      return;
    }

    _histSub = _firestoreService.streamHistorial(uid).listen((historial) {
      _historial = historial;
      notifyListeners();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('Error leyendo historial: $e');
    });

    _favSub = _firestoreService.streamFavoritos(uid).listen((favoritos) {
      _favoritos = favoritos;
      notifyListeners();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('Error leyendo favoritos: $e');
    });
  }

  Future<void> guardarHistorial(HistorialModel h) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _firestoreService.guardarHistorial(uid, h);
  }

  Future<void> agregarFavorito(FavoritoModel f) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _firestoreService.agregarFavorito(uid, f);
  }

  Future<void> quitarFavorito(String contenidoId) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _firestoreService.quitarFavorito(uid, contenidoId);
  }

  bool esFavorito(String contenidoId) =>
      _favoritos.any((f) => f.contenidoId == contenidoId);

  @override
  void dispose() {
    _histSub?.cancel();
    _favSub?.cancel();
    super.dispose();
  }
}