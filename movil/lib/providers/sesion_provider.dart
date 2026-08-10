import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/contenido_model.dart';
import '../models/sesion_model.dart';
import '../services/firestore_service.dart';

class SesionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ContenidoModel> _contenidos = [];
  SesionModel? _sesionActual;
  String? _uid;
  bool _uidInicializado = false;

  late final StreamSubscription<List<ContenidoModel>> _contenidosSub;
  StreamSubscription<SesionModel?>? _sesionActivaSub;

  List<ContenidoModel> get contenidos => _contenidos;
  SesionModel? get sesionActual => _sesionActual;
  String? get uid => _uid;

  SesionProvider() {
    _contenidosSub = _firestoreService.streamContenidos().listen((contenidos) {
      _contenidos = contenidos;
      notifyListeners();
    });
  }

  /// Vincula el provider al usuario autenticado. Si el uid cambia,
  /// re-suscribe el stream de la sesión activa de ese usuario.
  void setUid(String? uid) {
    if (_uidInicializado && _uid == uid) {
      return;
    }
    _uidInicializado = true;
    _uid = uid;

    _sesionActivaSub?.cancel();
    _sesionActivaSub = null;
    _sesionActual = null;

    if (uid == null) {
      notifyListeners();
      return;
    }

    _sesionActivaSub =
        _firestoreService.streamSesionActiva(uid).listen((sesion) {
      _sesionActual = sesion;
      notifyListeners();
    });
  }

  Future<void> seleccionarModo(ContenidoModel contenido) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    final sesion = SesionModel(
      modoActual: contenido.modo,
      contenidoId: contenido.id,
      estado: 'activa',
      inicioTimestamp: DateTime.now(),
    );
    await _firestoreService.actualizarSesion(sesion, uid);
  }

  Future<void> finalizarSesion() async {
    final uid = _uid;
    final sesion = _sesionActual;
    if (uid == null || sesion == null) {
      return;
    }

    final finalizada = SesionModel(
      modoActual: sesion.modoActual,
      contenidoId: sesion.contenidoId,
      estado: 'finalizada',
      inicioTimestamp: sesion.inicioTimestamp,
      frecuenciaCardiaca: sesion.frecuenciaCardiaca,
    );
    await _firestoreService.actualizarSesion(finalizada, uid);
  }

  @override
  void dispose() {
    _contenidosSub.cancel();
    _sesionActivaSub?.cancel();
    super.dispose();
  }
}