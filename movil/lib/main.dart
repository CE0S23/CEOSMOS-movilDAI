import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/historial_provider.dart';
import 'providers/sesion_provider.dart';
import 'providers/wearable_provider.dart';
import 'screens/dispositivos_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/seleccion_modo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SesionProvider>(
          create: (_) => SesionProvider(),
          update: (_, auth, sesion) =>
              sesion!..setUid(auth.usuarioActual?.uid),
        ),
        ChangeNotifierProvider(create: (_) => WearableProvider()),
        ChangeNotifierProxyProvider<AuthProvider, HistorialProvider>(
          create: (_) => HistorialProvider(),
          update: (_, auth, historial) =>
              historial!..setUid(auth.usuarioActual?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'CEOSMOS',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212)),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF1E1E1E),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Decide la pantalla inicial según el estado de autenticación:
/// login si no hay usuario, [MainScaffold] si ya hay sesión.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.cargando && auth.usuarioActual == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.usuarioActual == null) {
      return const LoginScreen();
    }

    return const MainScaffold();
  }
}

/// Scaffold raíz con BottomNavigationBar de 4 pestañas.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _indice = 0;

  static const List<Widget> _pantallas = [
    SeleccionModoScreen(),
    DispositivosScreen(),
    HistorialScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) {
          setState(() => _indice = indice);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other),
            selectedIcon: Icon(Icons.devices_other),
            label: 'Dispositivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}