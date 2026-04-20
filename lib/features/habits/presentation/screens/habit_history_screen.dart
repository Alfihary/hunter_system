import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/habit_history_entry.dart';
import '../../domain/habit_summary.dart';
import '../providers/habits_controller.dart';

/// Pantalla de historial de un hábito.
///
/// ¿Qué hace?
/// Muestra:
/// - estado actual del hábito
/// - racha actual
/// - historial de los últimos 14 días
///
/// ¿Para qué sirve?
/// Para dar visibilidad real del progreso diario.
class HabitHistoryScreen extends ConsumerWidget {
  final HabitSummary initialHabit;

  const HabitHistoryScreen({
    super.key,
    required this.initialHabit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentHabit =
        ref.watch(currentHabitSummaryProvider(initialHabit.id)) ?? initialHabit;

    final historyAsync = ref.watch(habitHistoryProvider(initialHabit.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial del hábito'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    currentHabit.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentHabit.category.label} • +${currentHabit.xpReward} XP',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Racha actual: ${currentHabit.currentStreak} día(s)',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final error = await ref
                          .read(habitsControllerProvider.notifier)
                          .toggleHabitForToday(currentHabit.id);

                      ref.invalidate(habitHistoryProvider(currentHabit.id));

                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                    icon: Icon(
                      currentHabit.completedToday
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    label: Text(
                      currentHabit.completedToday
                          ? 'Quitar marca de hoy'
                          : 'Marcar hoy',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Últimos 14 días',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay historial disponible.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: entries
                    .map((entry) => _HistoryEntryCard(entry: entry))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final HabitHistoryEntry entry;

  const _HistoryEntryCard({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(entry.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          entry.completed ? Icons.check_circle : Icons.cancel_outlined,
        ),
        title: Text(dateLabel),
        subtitle: Text(
          entry.completed
              ? 'Completado • +${entry.xpEarned} XP'
              : 'No completado',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return '$weekday $day $month';
  }
}