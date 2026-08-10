import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wearable_provider.dart';

class MonitoreoWearableScreen extends StatelessWidget {
  const MonitoreoWearableScreen({super.key});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'buscando':
        return Colors.amber;
      case 'conectado':
        return Colors.green;
      case 'conectado_respaldo':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'desconectado':
        return Colors.blueGrey;
      case 'inactivo':
      default:
        return Colors.grey;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'conectado_respaldo':
        return 'CONECTADO (RESPALDO)';
      default:
        return estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wearableProvider = context.watch<WearableProvider>();
    final estado = wearableProvider.estadoConexion;
    final ultimoDato = wearableProvider.ultimoDato;
    final alertaCritica = wearableProvider.alertaCritica;

    final colorEstado = _colorEstado(estado);
    final mostrarBuscar = estado == 'inactivo' || estado == 'error';
    final mostrarDesconectar =
        estado == 'conectado' ||
        estado == 'conectado_respaldo' ||
        estado == 'buscando';
    final mostrarDatos = estado == 'conectado' ||
        estado == 'conectado_respaldo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChipEstado(
            estado: estado,
            color: colorEstado,
            texto: _textoEstado(estado),
          ),
          if (alertaCritica) const _BannerAlertaCritica(),
          if (estado == 'buscando') const LinearProgressIndicator(),
          const SizedBox(height: 24),
          if (ultimoDato != null && mostrarDatos) ...[
            Row(
              children: [
                Expanded(
                  child: _MetricaTarjeta(
                    icon: Icons.favorite,
                    color: Colors.red,
                    etiqueta: 'Frecuencia cardíaca',
                    valor: '${ultimoDato.frecuenciaCardiaca} bpm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricaTarjeta(
                    icon: Icons.directions_walk,
                    color: Colors.blue,
                    etiqueta: 'Pasos',
                    valor: '${ultimoDato.pasos}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricaTarjeta(
              icon: Icons.monitor_heart,
              color: Colors.teal,
              etiqueta: 'Estado',
              valor: ultimoDato.estado,
            ),
            const SizedBox(height: 24),
          ],
          if (mostrarBuscar)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.read<WearableProvider>().iniciarEscaneo(),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Buscar wearable'),
              ),
            ),
          if (mostrarDesconectar)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<WearableProvider>().desconectar(),
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Desconectar'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String estado;
  final Color color;
  final String texto;

  const _ChipEstado({
    required this.estado,
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Chip(
        backgroundColor: color.withValues(alpha: 0.2),
        avatar: Icon(Icons.circle, color: color, size: 14),
        label: Text(texto),
      ),
    );
  }
}

class _BannerAlertaCritica extends StatelessWidget {
  const _BannerAlertaCritica();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ Frecuencia cardíaca elevada',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaTarjeta extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String etiqueta;
  final String valor;

  const _MetricaTarjeta({
    required this.icon,
    required this.color,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}