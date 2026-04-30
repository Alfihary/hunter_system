import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/hunter_panel.dart';
import '../../../../shared/presentation/widgets/hunter_section_label.dart';
import '../../domain/habit_category.dart';
import '../../domain/habit_dashboard.dart';
import '../../domain/habit_summary.dart';
import '../providers/habits_controller.dart';

/// Pantalla principal de hábitos.
///
/// ¿Qué hace?
/// - muestra dashboard RPG
/// - filtra por categoría
/// - lista hábitos
/// - permite marcar hoy
/// - permite editar, eliminar y abrir historial
///
/// ¿Para qué sirve?
/// Para convertir hábitos diarios en progreso visible tipo RPG.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(habitsControllerProvider);
    final selectedFilter = ref.watch(selectedHabitCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hábitos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/form'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hábito'),
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                Text(error.toString(), textAlign: TextAlign.center),
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
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(habitsControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardCard(dashboard: overview.dashboard),
                const SizedBox(height: 16),
                _CategoryFilterBar(selectedFilter: selectedFilter),
                const SizedBox(height: 16),
                const HunterSectionLabel('CHECKLIST DE HOY'),
                const SizedBox(height: 12),
                if (overview.habits.isEmpty)
                  const _EmptyHabitsView()
                else
                  ...overview.habits.map(
                    (habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HabitCard(habit: habit),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final HabitDashboard dashboard;

  const _DashboardCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final progress = dashboard.totalHabits <= 0
        ? 0.0
        : (dashboard.completedToday / dashboard.totalHabits).clamp(0.0, 1.0);

    return HunterPanel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('PANEL RPG DE HÁBITOS'),
          const SizedBox(height: 8),
          Text(
            '${dashboard.completedToday} / ${dashboard.totalHabits} completados hoy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'XP hoy',
                  value: dashboard.xpEarnedToday.toString(),
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'XP total',
                  value: dashboard.xpEarnedOverall.toString(),
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  final HabitCategory? selectedFilter;

  const _CategoryFilterBar({required this.selectedFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('FILTRO'),
          const SizedBox(height: 12),
          Wrap(
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
          ),
        ],
      ),
    );
  }
}

class _EmptyHabitsView extends StatelessWidget {
  const _EmptyHabitsView();

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
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
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitSummary habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return HunterPanel(
      highlighted: habit.completedToday,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  _iconForCategory(habit.category),
                  color: scheme.primary,
                ),
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
                    const SizedBox(height: 3),
                    Text(
                      '${habit.category.label} • +${habit.xpReward} XP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                habit.completedToday
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: habit.completedToday ? scheme.primary : scheme.outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SmallInfoChip(
                icon: Icons.local_fire_department_outlined,
                label: 'Racha ${habit.currentStreak}',
              ),
              const SizedBox(width: 8),
              _SmallInfoChip(
                icon: Icons.bolt_outlined,
                label: '+${habit.xpReward} XP',
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                icon: Icon(
                  habit.completedToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                label: Text(habit.completedToday ? 'Hecho hoy' : 'Marcar hoy'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/habits/history', extra: habit);
                },
                icon: const Icon(Icons.history),
                label: const Text('Historial'),
              ),
              PopupMenuButton<_HabitMenuAction>(
                tooltip: 'Más opciones',
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HabitMenuAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _HabitMenuAction.delete,
                    child: Text('Eliminar'),
                  ),
                ],
                onSelected: (action) async {
                  switch (action) {
                    case _HabitMenuAction.edit:
                      context.push('/habits/form', extra: habit);
                      break;
                    case _HabitMenuAction.delete:
                      await _confirmDelete(context, ref, habit);
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitSummary habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar hábito'),
          content: Text('¿Seguro que quieres eliminar "${habit.name}"?'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
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

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

enum _HabitMenuAction { edit, delete }
