import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/workout_routine_summary.dart';
import '../providers/workout_controller.dart';

/// Pantalla principal del módulo de entrenamiento.
///
/// ¿Qué hace?
/// Muestra las rutinas existentes con estilo RPG:
/// - iniciar entrenamiento
/// - crear rutina
/// - eliminar rutina
/// - acceder a historial
///
/// ¿Para qué sirve?
/// Es el centro de mando del módulo de entrenamiento.
class WorkoutRoutinesScreen extends ConsumerWidget {
  const WorkoutRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(workoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: () => context.push('/workouts/history'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workouts/form'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.read(workoutControllerProvider.notifier).reload(),
        ),
        data: (routines) {
          if (routines.isEmpty) {
            return const _EmptyWorkoutView();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Header(),
              const SizedBox(height: 20),
              ...routines.map((routine) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoutineCard(routine: routine),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// ================= HEADER RPG =================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ENTRENAMIENTO',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Forja tu progreso',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

/// ================= ERROR =================

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('No se pudieron cargar las rutinas.'),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// ================= EMPTY =================

class _EmptyWorkoutView extends StatelessWidget {
  const _EmptyWorkoutView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 56),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes rutinas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera rutina y comienza tu progreso como cazador.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= CARD =================

class _RoutineCard extends ConsumerWidget {
  final WorkoutRoutineSummary routine;

  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Nombre
          Text(routine.name, style: Theme.of(context).textTheme.titleMedium),

          /// Descripción
          if (routine.description != null && routine.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                routine.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: 10),

          /// Info
          Row(
            children: [
              const Icon(Icons.list, size: 16),
              const SizedBox(width: 6),
              Text('${routine.exerciseCount} ejercicios'),
            ],
          ),

          const SizedBox(height: 14),

          /// Botones
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/workouts/session/${routine.id}');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Entrenar'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Eliminar rutina'),
                        content: Text('¿Eliminar "${routine.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true) return;

                  final error = await ref
                      .read(workoutControllerProvider.notifier)
                      .deleteRoutine(routine.id);

                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
