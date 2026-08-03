import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/favorito_model.dart';
import '../models/historial_model.dart';

/// Provee historial de sesiones terminadas y la lista de favoritos,
/// sincronizados en tiempo real con Firestore.
class HistorialProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<HistorialModel> _historial = [];
  List<FavoritoModel> _favoritos = [];

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _histSub;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _favSub;

  List<HistorialModel> get historial => _historial;
  List<FavoritoModel> get favoritos => _favoritos;

  HistorialProvider() {
    _histSub = _db
        .collection('historial')
        .orderBy('inicio', descending: true)
        .snapshots()
        .listen((snap) {
      _historial = snap.docs
          .map((doc) => HistorialModel.fromFirestore(doc.id, doc.data()))
          .toList();
      notifyListeners();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('Error leyendo historial: $e');
    });

    _favSub = _db.collection('favoritos').snapshots().listen((snap) {
      _favoritos = snap.docs
          .map((doc) => FavoritoModel.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('Error leyendo favoritos: $e');
    });
  }

  Future<void> guardarHistorial(HistorialModel h) async {
    try {
      await _db.collection('historial').doc(h.id).set(h.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('Error guardando historial: $e');
    }
  }

  Future<void> agregarFavorito(FavoritoModel f) async {
    try {
      await _db.collection('favoritos').doc(f.contenidoId).set(f.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('Error agregando favorito: $e');
    }
  }

  Future<void> quitarFavorito(String contenidoId) async {
    try {
      await _db.collection('favoritos').doc(contenidoId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error quitando favorito: $e');
    }
  }

  bool esFavorito(String contenidoId) =>
      _favoritos.any((f) => f.contenidoId == contenidoId);

  @override
  void dispose() {
    _histSub.cancel();
    _favSub.cancel();
    super.dispose();
  }
}