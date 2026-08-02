import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wearable_gatt_provider.dart';

class WearableHomeScreen extends StatelessWidget {
  const WearableHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WearableGattProvider>();
    final activo = provider.advertisingActivo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CEOSMOS Wearable'),
      ),
      body: Center(
        child: activo ? _PantallaActiva() : _BotonIniciar(),
      ),
    );
  }
}

class _BotonIniciar extends StatelessWidget {
  const _BotonIniciar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () => context.read<WearableGattProvider>().iniciar(),
          icon: const Icon(Icons.bluetooth_searching),
          label: const Text('Iniciar'),
        ),
        const SizedBox(height: 12),
        const Text('Iniciar advertising y simulación BLE'),
      ],
    );
  }
}

class _PantallaActiva extends StatelessWidget {
  const _PantallaActiva();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WearableGattProvider>();
    final dato = provider.ultimoDato;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de conexión del central
          provider.centralConectado
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Central conectado'),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Esperando central...'),
                  ],
                ),
          const SizedBox(height: 24),
          // Frecuencia cardíaca grande
          Text(
            dato != null ? '${dato.frecuenciaCardiaca}' : '--',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text('bpm', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
          Text('Pasos: ${dato?.pasos ?? 0}'),
          const SizedBox(height: 4),
          Text('Estado: ${dato?.estado ?? '-'}'),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () =>
                    context.read<WearableGattProvider>().pausarSesion(),
                child: const Text('Pausar'),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: () =>
                    context.read<WearableGattProvider>().reanudarSesion(),
                child: const Text('Reanudar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<WearableGattProvider>().detener(),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }
}