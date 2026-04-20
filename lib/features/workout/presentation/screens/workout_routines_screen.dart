import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/workout_routine_summary.dart';
import '../providers/workout_controller.dart';

/// Pantalla principal del módulo de entrenamiento.
///
/// ¿Qué hace?
/// Muestra la lista de rutinas existentes y permite:
/// - crear rutina
/// - iniciar sesión
/// - eliminar rutina
///
/// ¿Para qué sirve?
/// Es el punto de entrada del módulo workout.
class WorkoutRoutinesScreen extends ConsumerWidget {
  const WorkoutRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(workoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workouts/form'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: routinesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No se pudieron cargar las rutinas.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.read(workoutControllerProvider.notifier).reload();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (routines) {
          if (routines.isEmpty) {
            return const _EmptyWorkoutView();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final routine = routines[index];
              return _RoutineCard(routine: routine);
            },
          );
        },
      ),
    );
  }
}

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
            const Icon(Icons.fitness_center, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes rutinas.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera rutina para empezar a registrar entrenamientos reales.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final WorkoutRoutineSummary routine;

  const _RoutineCard({
    required this.routine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routine.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (routine.description != null && routine.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(routine.description!),
              ),
            const SizedBox(height: 6),
            Text('Ejercicios: ${routine.exerciseCount}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context.push('/workouts/session/${routine.id}');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Entrenar'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Eliminar rutina'),
                          content: Text(
                            '¿Seguro que quieres eliminar "${routine.name}"?',
                          ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}