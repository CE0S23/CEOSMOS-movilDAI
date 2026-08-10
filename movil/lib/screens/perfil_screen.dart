import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Perfil del usuario autenticado: email y cierre de sesión.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuarioActual;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 44),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              usuario?.email ?? 'Sin sesión',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'UID: ${usuario?.uid ?? '—'}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().cerrarSesion();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}