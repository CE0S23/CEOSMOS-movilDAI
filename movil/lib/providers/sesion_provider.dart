import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/contenido_model.dart';
import '../models/sesion_model.dart';
import '../services/firestore_service.dart';

class SesionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ContenidoModel> _contenidos = [];
  SesionModel? _sesionActual;

  late final StreamSubscription<List<ContenidoModel>> _contenidosSub;
  late final StreamSubscription<SesionModel?> _sesionActivaSub;

  List<ContenidoModel> get contenidos => _contenidos;
  SesionModel? get sesionActual => _sesionActual;

  SesionProvider() {
    _contenidosSub = _firestoreService.streamContenidos().listen((contenidos) {
      _contenidos = contenidos;
      notifyListeners();
    });

    _sesionActivaSub =
        _firestoreService.streamSesionActiva().listen((sesion) {
      _sesionActual = sesion;
      notifyListeners();
    });
  }

  Future<void> seleccionarModo(ContenidoModel contenido) async {
    final sesion = SesionModel(
      modoActual: contenido.modo,
      contenidoId: contenido.id,
      estado: 'activa',
      inicioTimestamp: DateTime.now(),
    );
    await _firestoreService.actualizarSesion(sesion);
  }

  Future<void> finalizarSesion() async {
    final sesion = _sesionActual;
    if (sesion == null) {
      return;
    }
    final finalizada = SesionModel(
      modoActual: sesion.modoActual,
      contenidoId: sesion.contenidoId,
      estado: 'finalizada',
      inicioTimestamp: sesion.inicioTimestamp,
      frecuenciaCardiaca: sesion.frecuenciaCardiaca,
    );
    await _firestoreService.actualizarSesion(finalizada);
  }

  @override
  void dispose() {
    _contenidosSub.cancel();
    _sesionActivaSub.cancel();
    super.dispose();
  }
}
