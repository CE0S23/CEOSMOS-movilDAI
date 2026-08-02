import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/sesion_provider.dart';
import 'providers/wearable_provider.dart';
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
        ChangeNotifierProvider(create: (_) => SesionProvider()),
        ChangeNotifierProvider(create: (_) => WearableProvider()),
      ],
      child: MaterialApp(
        title: 'CEOSMOS',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const SeleccionModoScreen(),
      ),
    );
  }
}