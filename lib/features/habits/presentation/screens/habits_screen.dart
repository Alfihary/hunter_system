import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/habit_category.dart';
import '../../domain/habit_dashboard.dart';
import '../../domain/habit_summary.dart';
import '../../domain/habits_overview.dart';
import '../providers/habits_controller.dart';

/// Pantalla principal de hábitos.
///
/// ¿Qué hace?
/// - muestra dashboard RPG
/// - filtra por categoría
/// - lista hábitos
/// - permite marcar hoy, editar, eliminar y abrir historial
///
/// ¿Para qué sirve?
/// Es la vista principal del módulo de hábitos.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(habitsControllerProvider);
    final selectedFilter = ref.watch(selectedHabitCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/form'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hábito'),
      ),
      body: overviewAsync.when(
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
                  'Ocurrió un error al cargar el módulo de hábitos.',
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
                    ref.read(habitsControllerProvider.notifier).reload();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (overview) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DashboardCard(dashboard: overview.dashboard),
              const SizedBox(height: 16),
              _CategoryFilterBar(
                selectedFilter: selectedFilter,
              ),
              const SizedBox(height: 16),
              if (overview.habits.isEmpty)
                const _EmptyHabitsView()
              else
                ...overview.habits.map(
                  (habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HabitCard(habit: habit),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final HabitDashboard dashboard;

  const _DashboardCard({
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.shield_moon_outlined),
                const SizedBox(width: 8),
                Text(
                  'Panel RPG de hábitos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Hábitos',
                    value: dashboard.totalHabits.toString(),
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Hechos hoy',
                    value: dashboard.completedToday.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'XP hoy',
                    value: dashboard.xpEarnedToday.toString(),
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'XP total',
                    value: dashboard.xpEarnedOverall.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  final HabitCategory? selectedFilter;

  const _CategoryFilterBar({
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selectedFilter == null,
          onSelected: (_) {
            ref
                .read(selectedHabitCategoryFilterProvider.notifier)
                .setFilter(null);
          },
        ),
        ...HabitCategory.values.map(
          (category) => ChoiceChip(
            label: Text(category.label),
            selected: selectedFilter == category,
            onSelected: (_) {
              ref
                  .read(selectedHabitCategoryFilterProvider.notifier)
                  .setFilter(category);
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyHabitsView extends StatelessWidget {
  const _EmptyHabitsView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes hábitos en este filtro.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea un hábito nuevo o cambia la categoría seleccionada.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitSummary habit;

  const _HabitCard({
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(_iconForCategory(habit.category)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${habit.category.label} • +${habit.xpReward} XP'),
                  const SizedBox(height: 4),
                  Text('Racha actual: ${habit.currentStreak} día(s)'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final error = await ref
                              .read(habitsControllerProvider.notifier)
                              .toggleHabitForToday(habit.id);

                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                        icon: Icon(
                          habit.completedToday
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        label: Text(
                          habit.completedToday ? 'Hecho hoy' : 'Marcar hoy',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/habits/history', extra: habit);
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Historial'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/habits/form', extra: habit);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Eliminar hábito'),
                                content: Text(
                                  '¿Seguro que quieres eliminar "${habit.name}"?',
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
                              .read(habitsControllerProvider.notifier)
                              .deleteHabit(habit.id);

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
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(HabitCategory category) {
    switch (category) {
      case HabitCategory.physical:
        return Icons.fitness_center;
      case HabitCategory.nutrition:
        return Icons.restaurant_outlined;
      case HabitCategory.recovery:
        return Icons.bedtime_outlined;
      case HabitCategory.mental:
        return Icons.psychology_outlined;
      case HabitCategory.control:
        return Icons.shield_outlined;
    }
  }
}