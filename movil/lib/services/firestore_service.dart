import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contenido_model.dart';
import '../models/sesion_model.dart';

class FirestoreService {
  static const String _contenidosCollection = 'contenidos';
  static const String _sesionActivaDoc = 'sesiones/activa';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ContenidoModel>> streamContenidos() {
    return _firestore
        .collection(_contenidosCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContenidoModel.fromFirestore(doc))
            .toList());
  }

  Stream<SesionModel?> streamSesionActiva() {
    return _firestore.doc(_sesionActivaDoc).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return SesionModel.fromFirestore(doc);
    });
  }

  Future<void> actualizarSesion(SesionModel sesion) async {
    try {
      await _firestore
          .doc(_sesionActivaDoc)
          .set(sesion.toMap(), SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error actualizando sesión: $e');
    }
  }

  Future<void> actualizarFrecuenciaCardiaca(int valor) async {
    try {
      await _firestore.doc(_sesionActivaDoc).update({
        'frecuenciaCardiaca': valor,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error actualizando frecuencia cardíaca: $e');
    }
  }
}