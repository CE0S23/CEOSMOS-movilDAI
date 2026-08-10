import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/historial_model.dart';
import '../providers/historial_provider.dart';

/// Historial de sesiones terminadas del usuario autenticado.
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return '—';
    }
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<HistorialProvider>().historial;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: historial.isEmpty
          ? const Center(
              child: Text(
                'Sin sesiones registradas aún',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historial.length,
              itemBuilder: (context, index) {
                final HistorialModel h = historial[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      h.estado == 'finalizada'
                          ? Icons.check_circle
                          : Icons.timelapse,
                      color: h.estado == 'finalizada'
                          ? Colors.green
                          : Colors.amber,
                    ),
                    title: Text(h.modoActual.isEmpty ? 'Sesión' : h.modoActual),
                    subtitle: Text(
                      '${_formatearFecha(h.inicio)} · '
                      '${h.duracionSegundos ~/ 60} min · '
                      'FC máx ${h.frecuenciaMax}',
                    ),
                    trailing: Text(
                      h.estado,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}