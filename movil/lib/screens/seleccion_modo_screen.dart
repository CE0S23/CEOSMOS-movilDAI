import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contenido_model.dart';
import '../providers/sesion_provider.dart';
import 'monitoreo_wearable_screen.dart';

class SeleccionModoScreen extends StatelessWidget {
  const SeleccionModoScreen({super.key});

  Color _parseColor(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    final intValue = int.tryParse(value, radix: 16) ?? 0xFF000000;
    return Color(intValue);
  }

  @override
  Widget build(BuildContext context) {
    final sesionProvider = context.watch<SesionProvider>();
    final contenidos = sesionProvider.contenidos;
    final sesionActual = sesionProvider.sesionActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CEOSMOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Monitoreo wearable',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MonitoreoWearableScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (sesionActual != null && sesionActual.estado == 'activa')
            _SesionActivaBanner(modoActual: sesionActual.modoActual),
          Expanded(
            child: contenidos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: contenidos.length,
                    itemBuilder: (context, index) {
                      final contenido = contenidos[index];
                      return _ModoTarjeta(
                        contenido: contenido,
                        onColor: _parseColor(contenido.colorAcento),
                        onColorSecundario: contenido.colorSecundario.isEmpty
                            ? _parseColor(contenido.colorAcento)
                            : _parseColor(contenido.colorSecundario),
                        onIcono: _iconoPara(contenido.iconoNombre),
                        onTap: () {
                          context
                              .read<SesionProvider>()
                              .seleccionarModo(contenido);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Modo ${contenido.titulo} activado'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModoTarjeta extends StatelessWidget {
  final ContenidoModel contenido;
  final Color onColor;
  final Color onColorSecundario;
  final IconData onIcono;
  final VoidCallback onTap;

  const _ModoTarjeta({
    required this.contenido,
    required this.onColor,
    required this.onColorSecundario,
    required this.onIcono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [onColor, onColorSecundario],
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(onIcono, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      contenido.tipoContenido,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    contenido.titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconoPara(String nombre) {
  switch (nombre) {
    case 'self_improvement':
      return Icons.self_improvement;
    case 'headphones':
      return Icons.headphones;
    case 'format_quote_rounded':
      return Icons.format_quote_rounded;
    case 'music_note':
      return Icons.music_note;
    default:
      return Icons.auto_awesome;
  }
}

class _SesionActivaBanner extends StatelessWidget {
  final String modoActual;

  const _SesionActivaBanner({required this.modoActual});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.play_circle_fill),
      content: Text('Sesión activa: $modoActual'),
      actions: [
        TextButton(
          onPressed: () =>
              context.read<SesionProvider>().finalizarSesion(),
          child: const Text('Finalizar'),
        ),
      ],
    );
  }
}