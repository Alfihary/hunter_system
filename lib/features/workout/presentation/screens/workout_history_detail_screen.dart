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
        error: (error, _) => _ErrorView(error: error.toString()),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('No se encontró la sesión.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(detail: detail),
              const SizedBox(height: 16),
              const _SectionLabel('EJERCICIOS'),
              const SizedBox(height: 10),

              ...detail.exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(exercise: exercise),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ================= RESUMEN =================

class _SummaryCard extends StatelessWidget {
  final WorkoutHistoryDetail detail;

  const _SummaryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('RESUMEN DE BATALLA'),
          const SizedBox(height: 8),
          Text(
            detail.routineName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Sets', value: '${detail.totalSets}'),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Tiempo',
                  value: _formatDuration(detail.duration),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Volumen',
                  value: detail.totalVolume.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fecha: ${detail.endedAt.day}/${detail.endedAt.month}/${detail.endedAt.year}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// ================= EJERCICIO =================

class _ExerciseCard extends StatelessWidget {
  final dynamic exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            exercise.muscleGroup,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          ...exercise.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Text('Set ${set.setOrder}')),
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
    );
  }

  static String _setText(WorkoutHistorySetEntry set) {
    switch (set.setType) {
      case WorkoutSetType.normal:
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

/// ================= MINI STAT =================

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label),
      ],
    );
  }
}

/// ================= UI BASE =================

class _Panel extends StatelessWidget {
  final Widget child;
  final bool highlighted;

  const _Panel({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF1D2033) : const Color(0xFF181827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF55C8FF).withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
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
        color: const Color(0xFF8C7CFF),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Error al cargar la sesión'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
