import 'package:cloud_firestore/cloud_firestore.dart';

/// Contenido marcado como favorito, guardado en `favoritos/{contenidoId}`.
class FavoritoModel {
  final String contenidoId;
  final String modo;
  final DateTime agregado;

  FavoritoModel({
    required this.contenidoId,
    required this.modo,
    DateTime? agregado,
  }) : agregado = agregado ?? DateTime.now();

  factory FavoritoModel.fromMap(String id, Map<String, dynamic> data) {
    return FavoritoModel(
      contenidoId: id,
      modo: data['modo'] as String? ?? '',
      agregado: (data['agregado'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contenidoId': contenidoId,
      'modo': modo,
      'agregado': Timestamp.fromDate(agregado),
    };
  }
}