import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/theme_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// Pantalla principal protegida.
///
/// ¿Qué hace?
/// Actúa como dashboard de entrada a los módulos principales.
///
/// ¿Para qué sirve?
/// Organiza la navegación de la app desde un punto central.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunter System'),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('Bienvenido, ${user?.name ?? 'Jugador'}'),
              subtitle: Text(user?.email ?? 'Sin correo'),
              leading: const CircleAvatar(
                child: Icon(Icons.shield_moon_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Hábitos'),
              subtitle: const Text(
                'Crear hábitos, marcarlos hoy y construir rachas',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/habits'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Entrenamiento'),
              subtitle: const Text('Rutinas, sesiones reales e historial'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/workouts'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('Nutrición'),
              subtitle: const Text(
                'Manual, API, código de barras y resumen diario',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/nutrition'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Health'),
              subtitle: const Text(
                'Pasos, sueño y actividad automática del dispositivo',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/health'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_graph_outlined),
              title: const Text('Hunter RPG'),
              subtitle: const Text('Nivel, XP, rangos, títulos y logros'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/rpg'),
            ),
          ),
        ],
      ),
    );
  }
}
