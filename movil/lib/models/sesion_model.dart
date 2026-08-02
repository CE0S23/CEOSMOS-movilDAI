import 'package:cloud_firestore/cloud_firestore.dart';

class SesionModel {
  final String modoActual;
  final String contenidoId;
  final String estado;
  final DateTime? inicioTimestamp;
  final int? frecuenciaCardiaca;

  SesionModel({
    required this.modoActual,
    required this.contenidoId,
    required this.estado,
    this.inicioTimestamp,
    this.frecuenciaCardiaca,
  });

  factory SesionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SesionModel(
      modoActual: data['modoActual'] as String? ?? '',
      contenidoId: data['contenidoId'] as String? ?? '',
      estado: data['estado'] as String? ?? '',
      inicioTimestamp: (data['inicioTimestamp'] as Timestamp?)?.toDate(),
      frecuenciaCardiaca: data['frecuenciaCardiaca'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modoActual': modoActual,
      'contenidoId': contenidoId,
      'estado': estado,
      'inicioTimestamp': inicioTimestamp != null
          ? Timestamp.fromDate(inicioTimestamp!)
          : null,
      'frecuenciaCardiaca': frecuenciaCardiaca,
    };
  }
}
