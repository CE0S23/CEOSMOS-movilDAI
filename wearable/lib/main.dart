import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/wearable_gatt_provider.dart';
import 'screens/wearable_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WearableGattProvider(),
      child: MaterialApp(
        title: 'CEOSMOS Wearable',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.teal),
        ),
        home: const WearableHomeScreen(),
      ),
    );
  }
}