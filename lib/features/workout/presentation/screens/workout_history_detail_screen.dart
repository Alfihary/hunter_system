import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/workout_history_detail.dart';
import '../../domain/workout_set_type.dart';
import '../providers/workout_controller.dart';

/// Pantalla de detalle de una sesión terminada.
///
/// ¿Qué hace?
/// Muestra:
/// - resumen general
/// - duración
/// - volumen
/// - ejercicios trabajados
/// - sets por ejercicio
///
/// ¿Para qué sirve?
/// Para analizar entrenamientos pasados con más contexto.
class WorkoutHistoryDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutHistoryDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutHistoryDetailProvider(workoutId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de sesión')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('No se encontró la sesión.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(detail: detail),
              const SizedBox(height: 12),
              ...detail.exercises.map(
                (exercise) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(exercise.muscleGroup),
                        const SizedBox(height: 10),
                        ...exercise.sets.map(
                          (set) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 58,
                                  child: Text('Set ${set.setOrder}'),
                                ),
                                Expanded(child: Text(_setText(set))),
                                if (set.setType == WorkoutSetType.dropSet)
                                  const _Badge(label: 'DROP'),
                                if (set.setType == WorkoutSetType.isometric)
                                  const _Badge(label: 'ISO'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _setText(WorkoutHistorySetEntry set) {
    switch (set.setType) {
      case WorkoutSetType.normal:
        return set.weight == null
            ? '${set.reps} reps'
            : '${set.reps} reps • ${set.weight} kg';
      case WorkoutSetType.dropSet:
        return set.weight == null
            ? '${set.reps} reps'
            : '${set.reps} reps • ${set.weight} kg';
      case WorkoutSetType.isometric:
        return set.weight == null
            ? '${set.durationSeconds}s'
            : '${set.durationSeconds}s • ${set.weight} kg';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final WorkoutHistoryDetail detail;

  const _SummaryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              detail.routineName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${detail.endedAt.day}/${detail.endedAt.month}/${detail.endedAt.year}',
            ),
            Text('Duración: ${_formatDuration(detail.duration)}'),
            Text('Sets totales: ${detail.totalSets}'),
            Text('Volumen total: ${detail.totalVolume.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(label),
    );
  }
}
