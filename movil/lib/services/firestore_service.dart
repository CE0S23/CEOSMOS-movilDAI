import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contenido_model.dart';
import '../models/favorito_model.dart';
import '../models/historial_model.dart';
import '../models/sesion_model.dart';

/// Servicio de Firestore con datos por usuario.
///
/// La sesión activa vive en `sesiones/{uid}` (un documento por usuario) y el
/// historial/favoritos en `usuarios/{uid}/historial/{id}` y
/// `usuarios/{uid}/favoritos/{id}`.
class FirestoreService {
  static const String _contenidosCollection = 'contenidos';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ContenidoModel>> streamContenidos() {
    return _firestore
        .collection(_contenidosCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContenidoModel.fromFirestore(doc))
            .toList());
  }

  Stream<SesionModel?> streamSesionActiva(String uid) {
    return _firestore.doc('sesiones/$uid').snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return SesionModel.fromFirestore(doc);
    });
  }

  Future<void> actualizarSesion(SesionModel sesion, String uid) async {
    try {
      await _firestore
          .doc('sesiones/$uid')
          .set(sesion.toMap(), SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error actualizando sesión: $e');
    }
  }

  Future<void> actualizarFrecuenciaCardiaca(int valor, String uid) async {
    try {
      await _firestore.doc('sesiones/$uid').update({
        'frecuenciaCardiaca': valor,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error actualizando frecuencia cardíaca: $e');
    }
  }

  Stream<List<HistorialModel>> streamHistorial(String uid) {
    return _firestore
        .collection('usuarios/$uid/historial')
        .orderBy('inicio', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => HistorialModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<List<FavoritoModel>> streamFavoritos(String uid) {
    return _firestore
        .collection('usuarios/$uid/favoritos')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FavoritoModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> guardarHistorial(String uid, HistorialModel h) async {
    try {
      await _firestore
          .collection('usuarios/$uid/historial')
          .doc(h.id)
          .set(h.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('Error guardando historial: $e');
    }
  }

  Future<void> agregarFavorito(String uid, FavoritoModel f) async {
    try {
      await _firestore
          .collection('usuarios/$uid/favoritos')
          .doc(f.contenidoId)
          .set(f.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('Error agregando favorito: $e');
    }
  }

  Future<void> quitarFavorito(String uid, String contenidoId) async {
    try {
      await _firestore
          .collection('usuarios/$uid/favoritos')
          .doc(contenidoId)
          .delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error quitando favorito: $e');
    }
  }

  /// Escribe un código de vinculación móvil → TV en `vinculaciones/{codigo}`.
  Future<void> crearVinculacion({
    required String codigo,
    required String uid,
    required String email,
    required DateTime expiraEn,
  }) async {
    try {
      await _firestore.doc('vinculaciones/$codigo').set({
        'uid': uid,
        'email': email,
        'creadoEn': FieldValue.serverTimestamp(),
        'expiraEn': expiraEn,
        'usado': false,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error creando vinculación: $e');
    }
  }

  /// Escucha en tiempo real el documento de vinculación `vinculaciones/{codigo}`.
  Stream<Map<String, dynamic>?> streamVinculacion(String codigo) {
    return _firestore.doc('vinculaciones/$codigo').snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return doc.data();
    });
  }
}