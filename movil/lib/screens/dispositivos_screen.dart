import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wearable_data_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wearable_provider.dart';
import '../services/firestore_service.dart';

/// Pantalla de Dispositivos: estado del wearable (BLE / respaldo TCP) y
/// vinculación de la Smart TV por código de 6 dígitos.
class DispositivosScreen extends StatefulWidget {
  const DispositivosScreen({super.key});

  @override
  State<DispositivosScreen> createState() => _DispositivosScreenState();
}

class _DispositivosScreenState extends State<DispositivosScreen> {
  final FirestoreService _firestore = FirestoreService();

  String? _codigo;
  DateTime? _expiraEn;
  Timer? _countdownTimer;
  Duration _restante = Duration.zero;
  bool _tvVinculada = false;
  StreamSubscription<Map<String, dynamic>?>? _vinculacionSub;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vinculacionSub?.cancel();
    super.dispose();
  }

  Future<void> _generarCodigo() async {
    final uid = context.read<AuthProvider>().usuarioActual?.uid;
    final email = context.read<AuthProvider>().usuarioActual?.email;
    if (uid == null || email == null) {
      return;
    }

    final codigo = _generarCodigoAleatorio();
    final expiraEn = DateTime.now().add(const Duration(minutes: 10));

    await _firestore.crearVinculacion(
      codigo: codigo,
      uid: uid,
      email: email,
      expiraEn: expiraEn,
    );

    _vinculacionSub?.cancel();
    _vinculacionSub = _firestore.streamVinculacion(codigo).listen((doc) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (doc != null && doc['usado'] == true) {
          _tvVinculada = true;
        }
      });
    });

    setState(() {
      _codigo = codigo;
      _expiraEn = expiraEn;
      _restante = const Duration(minutes: 10);
      _tvVinculada = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        final nuevo = _expiraEn!.difference(DateTime.now());
        _restante = nuevo.isNegative ? Duration.zero : nuevo;
        if (_restante == Duration.zero) {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String _generarCodigoAleatorio() {
    final rand = DateTime.now().microsecondsSinceEpoch;
    return ((rand % 900000) + 100000).toString();
  }

  String _estadoWearable(String estadoConexion) {
    switch (estadoConexion) {
      case 'conectado':
        return 'Vinculado por BLE';
      case 'conectado_respaldo':
        return 'Vinculado por respaldo TCP';
      case 'buscando':
        return 'Buscando...';
      case 'desconectado':
        return 'Desconectado';
      case 'error':
        return 'Error de conexión';
      default:
        return 'No vinculado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wearable = context.watch<WearableProvider>();
    final estado = wearable.estadoConexion;
    final dato = wearable.ultimoDato;

    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CardWearable(
            estado: _estadoWearable(estado),
            conectado: estado == 'conectado' ||
                estado == 'conectado_respaldo',
            dato: dato,
            colorEstado: _colorEstadoWearable(estado),
            onBuscar: () {
              context.read<WearableProvider>().iniciarEscaneo();
            },
            onDesconectar: () {
              context.read<WearableProvider>().desconectar();
            },
          ),
          const SizedBox(height: 16),
          _CardTv(
            codigo: _codigo,
            restante: _restante,
            vinculada: _tvVinculada,
            onGenerar: _generarCodigo,
          ),
        ],
      ),
    );
  }

  Color _colorEstadoWearable(String estado) {
    switch (estado) {
      case 'conectado':
        return Colors.green;
      case 'conectado_respaldo':
        return Colors.orange;
      case 'buscando':
        return Colors.amber;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _CardWearable extends StatelessWidget {
  final String estado;
  final bool conectado;
  final WearableDataModel? dato;
  final Color colorEstado;
  final VoidCallback onBuscar;
  final VoidCallback onDesconectar;

  const _CardWearable({
    required this.estado,
    required this.conectado,
    required this.dato,
    required this.colorEstado,
    required this.onBuscar,
    required this.onDesconectar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.watch, color: colorEstado),
                const SizedBox(width: 8),
                const Text(
                  'Wearable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado,
                    style:
                        TextStyle(color: colorEstado, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (dato != null) ...[
              const SizedBox(height: 12),
              Text('FC: ${dato!.frecuenciaCardiaca} bpm   ·   '
                  'Pasos: ${dato!.pasos}   ·   Estado: ${dato!.estado}'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: conectado ? onDesconectar : onBuscar,
                    icon: Icon(conectado
                        ? Icons.bluetooth_disabled
                        : Icons.bluetooth_searching),
                    label: Text(conectado ? 'Desconectar' : 'Buscar / reconectar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTv extends StatelessWidget {
  final String? codigo;
  final Duration restante;
  final bool vinculada;
  final VoidCallback onGenerar;

  const _CardTv({
    required this.codigo,
    required this.restante,
    required this.vinculada,
    required this.onGenerar,
  });

  String get _tiempoRestante {
    final minutos = restante.inMinutes.toString().padLeft(2, '0');
    final segundos = (restante.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tv,
                    color: vinculada ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Smart TV',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: vinculada
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vinculada ? 'TV vinculada ✓' : 'No vinculada',
                    style: TextStyle(
                      color: vinculada ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (codigo == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onGenerar,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generar código de vinculación'),
                ),
              )
            else ...[
              Center(
                child: Text(
                  codigo!,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Expira en $_tiempoRestante',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Ingresa este código en la TV',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
            if (vinculada) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Escribe este código en la pantalla de la TV para vincular.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}