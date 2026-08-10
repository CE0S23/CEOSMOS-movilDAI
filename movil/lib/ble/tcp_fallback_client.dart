import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/wearable_data_model.dart';

/// Cliente TCP de respaldo (loopback 127.0.0.1:8765).
///
/// Se usa SOLO cuando el escaneo BLE no encuentra el wearable. El BLE sigue
/// siendo el mecanismo primario; este cliente es un fallback adicional.
class TcpFallbackClient {
  static const String _host = '127.0.0.1';
  static const int _puerto = 8765;
  static const Duration _timeout = Duration(seconds: 3);

  /// Intenta conectar al servidor TCP del wearable en 127.0.0.1:8765.
  /// Devuelve el [Socket] si la conexión tiene éxito o `null` si falla.
  Future<Socket?> conectar() async {
    try {
      return await Socket.connect(
        _host,
        _puerto,
        timeout: _timeout,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Falló conexión TCP de respaldo: $e');
      return null;
    }
  }

  /// Lee líneas delimitadas por '\n' del [socket], parsea cada JSON a
  /// [WearableDataModel] y emite cada dato recibido.
  Stream<WearableDataModel> escucharDatos(Socket socket) {
    return socket
        .map((bytes) => utf8.decode(bytes, allowMalformed: true))
        .transform(const LineSplitter())
        .where((linea) => linea.trim().isNotEmpty)
        .map(_parsearDato);
  }

  /// Cierra el [socket] de forma segura.
  Future<void> cerrar(Socket socket) async {
    try {
      await socket.close();
    } catch (e) {
      // ignore: avoid_print
      print('Error cerrando socket TCP: $e');
    }
  }

  WearableDataModel _parsearDato(String linea) {
    final json = jsonDecode(linea) as Map<String, dynamic>;
    final timestampRaw = json['timestamp'] as String?;

    return WearableDataModel(
      frecuenciaCardiaca: json['frecuenciaCardiaca'] as int? ?? 0,
      pasos: json['pasos'] as int? ?? 0,
      estado: json['estado'] as String? ?? '',
      timestamp: timestampRaw != null
          ? DateTime.tryParse(timestampRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}