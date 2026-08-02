import 'dart:async';
import 'dart:math';

import '../models/wearable_data_model.dart';

/// Genera datos simulados de wearable (frecuencia cardíaca, pasos, estado) en
/// un tick por segundo, con rangos realistas y transiciones suaves.
class SimuladorDatosService {
  final Random _random = Random();
  final StreamController<WearableDataModel> _controller =
      StreamController<WearableDataModel>.broadcast();

  Timer? _timer;
  int _frecuencia = 72;
  int _pasos = 0;
  bool _pausado = false;
  String _estado = 'normal';

  /// Stream broadcast que emite una muestra por cada tick (1 seg).
  Stream<WearableDataModel> get streamDatos => _controller.stream;

  /// Arranca el temporizador de 1 segundo (no-op si ya está corriendo).
  void iniciar() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Detiene el temporizador.
  void detener() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pone el estado en "pausa" (los pasos dejan de acumularse).
  void pausar() {
    _pausado = true;
    _estado = 'pausa';
  }

  /// Sale del estado de pausa; el estado vuelve a derivarse de la frecuencia.
  void reanudar() {
    _pausado = false;
  }

  Future<void> _tick() async {
    if (!_pausado) {
      // Espiga de estrés: ~15% de probabilidad por tick, sube hasta ~8 bpm.
      if (_random.nextDouble() < 0.15) {
        _frecuencia += _random.nextInt(7) + 1;
      } else if (_frecuencia > 76) {
        // Vuelve gradualmente a la baja (máx 8 bpm entre subida/bajada).
        _frecuencia -= _random.nextInt(6) + 1;
      }
      _frecuencia = _frecuencia.clamp(60, 140);

      // Pasos: 0-3 por tick, solo si no está en pausa.
      _pasos += _random.nextInt(4);
    }

    _derivarEstado();

    _controller.add(WearableDataModel(
      frecuenciaCardiaca: _frecuencia,
      pasos: _pasos,
      estado: _estado,
      timestamp: DateTime.now(),
    ));
  }

  void _derivarEstado() {
    if (_pausado) {
      _estado = 'pausa';
      return;
    }
    if (_frecuencia >= 60 && _frecuencia <= 90) {
      _estado = 'flow';
    } else if (_frecuencia > 110) {
      _estado = 'estres';
    } else {
      _estado = 'normal';
    }
  }

  void dispose() {
    detener();
    _controller.close();
  }
}