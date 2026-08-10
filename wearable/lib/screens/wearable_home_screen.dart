import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wearable_gatt_provider.dart';

/// Carátula de reloj inteligente del wearable CEOSMOS.
///
/// Modo inactivo: watch face con la hora actual y botón circular "Iniciar
/// sesión". Modo activo: una métrica rotando cada 3 segundos en el centro,
/// anillo de progreso con el tiempo de sesión y botón circular rojo para
/// detener (con confirmación de doble tap de 2 segundos).
class WearableHomeScreen extends StatefulWidget {
  const WearableHomeScreen({super.key});

  @override
  State<WearableHomeScreen> createState() => _WearableHomeScreenState();
}

class _WearableHomeScreenState extends State<WearableHomeScreen> {
  Timer? _timerReloj;
  Timer? _timerRotacion;
  Timer? _timerConfirmacion;

  bool _sesionEnCurso = false;
  bool _confirmandoDetener = false;
  int _indiceMetrica = 0;
  late DateTime _inicioSesion;
  String? _estadoAnterior;

  @override
  void initState() {
    super.initState();
    _timerReloj = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timerReloj?.cancel();
    _timerRotacion?.cancel();
    _timerConfirmacion?.cancel();
    super.dispose();
  }

  Future<void> _confirmarYDetener() async {
    HapticFeedback.mediumImpact();
    _timerConfirmacion?.cancel();
    await context.read<WearableGattProvider>().detener();
    if (mounted) {
      setState(() => _confirmandoDetener = false);
    }
  }

  void _iniciarConfirmacion() {
    setState(() => _confirmandoDetener = true);
    _timerConfirmacion?.cancel();
    _timerConfirmacion = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _confirmandoDetener = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WearableGattProvider>();
    final activo = provider.advertisingActivo;
    final dato = provider.ultimoDato;

    // Haptic heavy al detectar estrés (solo en la transición al estado).
    final estado = dato?.estado;
    if (estado == 'estres' && _estadoAnterior != 'estres') {
      HapticFeedback.heavyImpact();
    }
    _estadoAnterior = estado;

    if (activo && !_sesionEnCurso) {
      _sesionEnCurso = true;
      _inicioSesion = DateTime.now();
      _indiceMetrica = 0;
      _timerRotacion?.cancel();
      _timerRotacion = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          setState(() => _indiceMetrica = (_indiceMetrica + 1) % 3);
        }
      });
    }
    if (!activo && _sesionEnCurso) {
      _sesionEnCurso = false;
      _timerRotacion?.cancel();
      _confirmandoDetener = false;
    }

    final estadoColor = _colorEstado(estado);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lado = math.min(
              constraints.maxWidth,
              constraints.maxHeight - 170,
            );
            final diametro = math.min(lado, 420.0).toDouble();

            return Stack(
              children: [
                Center(
                  child: _Caratula(
                    diametro: diametro,
                    activo: activo,
                    provider: provider,
                    indiceMetrica: _indiceMetrica,
                    progreso: _progresoSesion(),
                    colorAnillo: estadoColor,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 12,
                  child: _IndicadorCanal(canal: provider.canalActivo),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: activo
                      ? _ControlesActivo(
                          confirmando: _confirmandoDetener,
                          onConfirmarPrimerTap: _iniciarConfirmacion,
                          onDetener: _confirmarYDetener,
                          onPausar: () =>
                              context.read<WearableGattProvider>().pausarSesion(),
                          onReanudar: () => context
                              .read<WearableGattProvider>()
                              .reanudarSesion(),
                        )
                      : _BotonIniciarSesion(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.read<WearableGattProvider>().iniciar();
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'estres':
        return Colors.redAccent;
      case 'flow':
        return Colors.tealAccent;
      case 'pausa':
        return Colors.amber;
      case 'normal':
        return Colors.greenAccent;
      default:
        return Colors.tealAccent;
    }
  }

  /// Progreso del anillo: un giro completo por minuto de sesión.
  double _progresoSesion() {
    if (!_sesionEnCurso) {
      return 0;
    }
    final elapsed = DateTime.now().difference(_inicioSesion);
    return (elapsed.inMilliseconds % 60000) / 60000;
  }
}

/// Carátula circular con anillo de progreso y métrica central.
class _Caratula extends StatelessWidget {
  final double diametro;
  final bool activo;
  final WearableGattProvider provider;
  final int indiceMetrica;
  final double progreso;
  final Color colorAnillo;

  const _Caratula({
    required this.diametro,
    required this.activo,
    required this.provider,
    required this.indiceMetrica,
    required this.progreso,
    required this.colorAnillo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diametro,
      height: diametro,
      child: CustomPaint(
        painter: _AnilloProgresoPainter(progreso: progreso, color: colorAnillo),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colorAnillo.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: activo
                ? _MetricaRotativa(provider: provider, indice: indiceMetrica)
                : _RelojInactivo(),
          ),
        ),
      ),
    );
  }
}

/// Hora actual grande estilo watch face.
class _RelojInactivo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hora = '${now.hour.toString().padLeft(2, '0')}'
        ':${now.minute.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hora,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'CEOSMOS',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Métrica central rotando cada 3 segundos (corazón / pasos / estado),
/// con transición de fade entre métricas vía [AnimatedSwitcher].
class _MetricaRotativa extends StatelessWidget {
  final WearableGattProvider provider;
  final int indice;

  const _MetricaRotativa({required this.provider, required this.indice});

  @override
  Widget build(BuildContext context) {
    final dato = provider.ultimoDato;
    final estado = dato?.estado ?? '-';

    final Widget metrica = switch (indice % 3) {
      0 => _MetricaBpm(
          bpm: dato?.frecuenciaCardiaca ?? 0,
          estres: estado == 'estres',
        ),
      1 => _MetricaPasos(pasos: dato?.pasos ?? 0),
      _ => _MetricaEstado(estado: estado),
    };

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(indice % 3),
          child: metrica,
        ),
      ),
    );
  }
}

class _MetricaBpm extends StatefulWidget {
  final int bpm;
  final bool estres;

  const _MetricaBpm({required this.bpm, required this.estres});

  @override
  State<_MetricaBpm> createState() => _MetricaBpmState();
}

class _MetricaBpmState extends State<_MetricaBpm> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CorazonAnimado(estres: widget.estres),
          const SizedBox(height: 10),
          Text(
            '${widget.bpm}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'bpm',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _CorazonAnimado extends StatefulWidget {
  final bool estres;

  const _CorazonAnimado({required this.estres});

  @override
  State<_CorazonAnimado> createState() => _CorazonAnimadoState();
}

class _CorazonAnimadoState extends State<_CorazonAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.75,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CorazonAnimado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estres != widget.estres) {
      _controller.duration = widget.estres
          ? const Duration(milliseconds: 320)
          : const Duration(milliseconds: 900);
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Icon(
        Icons.favorite,
        color: widget.estres ? Colors.redAccent : Colors.red,
        size: 42,
      ),
    );
  }
}

class _MetricaPasos extends StatelessWidget {
  final int pasos;

  const _MetricaPasos({required this.pasos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk, color: Colors.lightBlueAccent, size: 44),
          const SizedBox(height: 10),
          Text(
            '$pasos',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'pasos',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _MetricaEstado extends StatelessWidget {
  final String estado;

  const _MetricaEstado({required this.estado});

  Color get _color => switch (estado) {
        'estres' => Colors.redAccent,
        'flow' => Colors.tealAccent,
        'pausa' => Colors.amber,
        _ => Colors.greenAccent,
      };

  IconData get _icono => switch (estado) {
        'estres' => Icons.bolt,
        'flow' => Icons.auto_awesome,
        'pausa' => Icons.pause_circle,
        _ => Icons.mood,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icono, color: _color, size: 48),
          const SizedBox(height: 10),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _color,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular de inicio (modo inactivo).
class _BotonIniciarSesion extends StatelessWidget {
  final VoidCallback onPressed;

  const _BotonIniciarSesion({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 34),
                  SizedBox(height: 2),
                  Text(
                    'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Controles del modo activo: Detener (con doble tap de confirmación) y
/// pausa/reanudar secundarios.
class _ControlesActivo extends StatelessWidget {
  final bool confirmando;
  final VoidCallback onConfirmarPrimerTap;
  final VoidCallback onDetener;
  final VoidCallback onPausar;
  final VoidCallback onReanudar;

  const _ControlesActivo({
    required this.confirmando,
    required this.onConfirmarPrimerTap,
    required this.onDetener,
    required this.onPausar,
    required this.onReanudar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: FilledButton(
            onPressed: confirmando ? onDetener : onConfirmarPrimerTap,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: confirmando ? Colors.redAccent : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: confirmando
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, size: 26),
                      Text('¿Seguro?',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, size: 30),
                      Text('Detener',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: onPausar,
              icon: const Icon(Icons.pause, size: 20),
              tooltip: 'Pausar',
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: onReanudar,
              icon: const Icon(Icons.play_arrow, size: 20),
              tooltip: 'Reanudar',
            ),
          ],
        ),
      ],
    );
  }
}

/// Indicador sutil del canal activo (BLE o Respaldo TCP) en la esquina.
class _IndicadorCanal extends StatelessWidget {
  final String canal;

  const _IndicadorCanal({required this.canal});

  @override
  Widget build(BuildContext context) {
    final (IconData icono, String texto, Color color) = switch (canal) {
      'ble' => (Icons.bluetooth, 'BLE', Colors.lightBlueAccent),
      'tcp' => (Icons.wifi, 'TCP', Colors.orangeAccent),
      _ => (Icons.bluetooth_disabled, '—', Colors.white24),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(fontSize: 11, color: color, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

/// Anillo de progreso circular alrededor de la carátula.
class _AnilloProgresoPainter extends CustomPainter {
  final double progreso;
  final Color color;

  const _AnilloProgresoPainter({required this.progreso, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - 5;
    const grosor = 5.0;

    final pista = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = Colors.white.withValues(alpha: 0.10);

    canvas.drawCircle(centro, radio, pista);

    final arco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      2 * math.pi * progreso,
      false,
      arco,
    );
  }

  @override
  bool shouldRepaint(_AnilloProgresoPainter oldDelegate) {
    return oldDelegate.progreso != progreso || oldDelegate.color != color;
  }
}