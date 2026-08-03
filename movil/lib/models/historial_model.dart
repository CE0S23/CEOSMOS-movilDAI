import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de una sesión terminada, guardado en `historial/`.
class HistorialModel {
  final String id;
  final String modoActual;
  final String contenidoId;
  final String estado;
  final DateTime? inicio;
  final DateTime? fin;
  final int duracionSegundos;
  final int pausas;
  final int frecuenciaMax;
  final int frecuenciaPromedio;

  const HistorialModel({
    required this.id,
    required this.modoActual,
    required this.contenidoId,
    required this.estado,
    this.inicio,
    this.fin,
    this.duracionSegundos = 0,
    this.pausas = 0,
    this.frecuenciaMax = 0,
    this.frecuenciaPromedio = 0,
  });

  factory HistorialModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return HistorialModel(
      id: id,
      modoActual: data['modoActual'] as String? ?? '',
      contenidoId: data['contenidoId'] as String? ?? '',
      estado: data['estado'] as String? ?? '',
      inicio: (data['inicio'] as Timestamp?)?.toDate(),
      fin: (data['fin'] as Timestamp?)?.toDate(),
      duracionSegundos: data['duracionSegundos'] as int? ?? 0,
      pausas: data['pausas'] as int? ?? 0,
      frecuenciaMax: data['frecuenciaMax'] as int? ?? 0,
      frecuenciaPromedio: data['frecuenciaPromedio'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modoActual': modoActual,
      'contenidoId': contenidoId,
      'estado': estado,
      'inicio': inicio != null ? Timestamp.fromDate(inicio!) : null,
      'fin': fin != null ? Timestamp.fromDate(fin!) : null,
      'duracionSegundos': duracionSegundos,
      'pausas': pausas,
      'frecuenciaMax': frecuenciaMax,
      'frecuenciaPromedio': frecuenciaPromedio,
    };
  }
}