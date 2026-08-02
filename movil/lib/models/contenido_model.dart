import 'package:cloud_firestore/cloud_firestore.dart';

class ContenidoModel {
  final String id;
  final String modo;
  final String titulo;
  final String tipoContenido;
  final String fondoUrl;
  final String audioUrl;
  final String colorAcento;

  ContenidoModel({
    required this.id,
    required this.modo,
    required this.titulo,
    required this.tipoContenido,
    required this.fondoUrl,
    required this.audioUrl,
    required this.colorAcento,
  });

  factory ContenidoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContenidoModel(
      id: doc.id,
      modo: data['modo'] as String? ?? '',
      titulo: data['titulo'] as String? ?? '',
      tipoContenido: data['tipoContenido'] as String? ?? '',
      fondoUrl: data['fondoUrl'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      colorAcento: data['colorAcento'] as String? ?? '',
    );
  }
}
