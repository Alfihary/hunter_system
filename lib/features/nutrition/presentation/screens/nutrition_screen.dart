import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/hunter_panel.dart';
import '../../../../shared/presentation/widgets/hunter_section_label.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition_day_overview.dart';
import '../../domain/nutrition_log_entry.dart';
import '../providers/nutrition_controller.dart';

/// Pantalla principal de nutrición.
///
/// ¿Qué hace?
/// - muestra resumen diario
/// - muestra progreso de calorías y macros
/// - permite cambiar fecha con límites
/// - permite editar metas
/// - permite registrar manualmente con FAB
/// - permite buscar alimento por API desde AppBar
/// - permite escanear código de barras desde AppBar
/// - lista alimentos agrupados por comida
///
/// ¿Para qué sirve?
/// Para controlar alimentación diaria con estilo Hunter System,
/// manteniendo compatibilidad con modo claro/oscuro.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(nutritionControllerProvider);
    final selectedDate = ref.watch(selectedNutritionDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta'),
        actions: [
          IconButton(
            tooltip: 'Escanear código',
            onPressed: () => context.push('/nutrition/barcode'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: 'Buscar alimento',
            onPressed: () => context.push('/nutrition/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Editar metas',
            onPressed: () => _showGoalsDialog(context, ref),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nutrition/log'),
        icon: const Icon(Icons.add),
        label: const Text('Manual'),
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (overview) {
          final sortedMealTypes = [...MealType.values]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final today = DateTime.now();
          final cleanToday = DateTime(today.year, today.month, today.day);
          final cleanSelectedDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );

          final hasLogsOnSelectedDate = MealType.values.any(
            (mealType) => overview.logsForMeal(mealType).isNotEmpty,
          );

          final canGoNext = cleanSelectedDate.isBefore(cleanToday);
          final canGoPrevious = hasLogsOnSelectedDate;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(nutritionControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DateSelector(
                  selectedDate: selectedDate,
                  canGoPrevious: canGoPrevious,
                  canGoNext: canGoNext,
                  onPrevious: () {
                    ref
                        .read(selectedNutritionDateProvider.notifier)
                        .goToPreviousDay();
                  },
                  onToday: () {
                    ref
                        .read(selectedNutritionDateProvider.notifier)
                        .goToToday();
                  },
                  onNext: () {
                    ref
                        .read(selectedNutritionDateProvider.notifier)
                        .goToNextDay();
                  },
                ),
                const SizedBox(height: 14),
                _SummaryCard(overview: overview),
                const SizedBox(height: 18),
                const HunterSectionLabel('REGISTROS DEL DÍA'),
                const SizedBox(height: 12),
                ...sortedMealTypes.map(
                  (mealType) => _MealSection(
                    mealType: mealType,
                    logs: overview.logsForMeal(mealType),
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

  Future<void> _showGoalsDialog(BuildContext context, WidgetRef ref) async {
    final overviewAsync = ref.read(nutritionControllerProvider);
    final overview = overviewAsync.asData?.value;

    if (overview == null) return;

    final caloriesController = TextEditingController(
      text: overview.goal.calories.toStringAsFixed(0),
    );
    final proteinController = TextEditingController(
      text: overview.goal.protein.toStringAsFixed(0),
    );
    final carbsController = TextEditingController(
      text: overview.goal.carbs.toStringAsFixed(0),
    );
    final fatsController = TextEditingController(
      text: overview.goal.fats.toStringAsFixed(0),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Metas diarias'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _GoalInput(controller: caloriesController, label: 'Calorías'),
                const SizedBox(height: 12),
                _GoalInput(controller: proteinController, label: 'Proteína'),
                const SizedBox(height: 12),
                _GoalInput(controller: carbsController, label: 'Carbohidratos'),
                const SizedBox(height: 12),
                _GoalInput(controller: fatsController, label: 'Grasas'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    final shouldSave = result == true;

    if (!shouldSave) {
      caloriesController.dispose();
      proteinController.dispose();
      carbsController.dispose();
      fatsController.dispose();
      return;
    }

    final calories = double.tryParse(caloriesController.text.trim());
    final protein = double.tryParse(proteinController.text.trim());
    final carbs = double.tryParse(carbsController.text.trim());
    final fats = double.tryParse(fatsController.text.trim());

    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();

    if (calories == null || protein == null || carbs == null || fats == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Metas inválidas.')));
      }
      return;
    }

    final error = await ref
        .read(nutritionControllerProvider.notifier)
        .updateGoals(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _GoalInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _GoalInput({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  const _DateSelector({
    required this.selectedDate,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                const HunterSectionLabel('DÍA SELECCIONADO'),
                const SizedBox(height: 4),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
          OutlinedButton(onPressed: onToday, child: const Text('Hoy')),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final NutritionDayOverview overview;

  const _SummaryCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final caloriesProgress = overview.goal.calories <= 0
        ? 0.0
        : (overview.summary.totalCalories / overview.goal.calories).clamp(
            0.0,
            1.0,
          );

    return HunterPanel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('RESUMEN DEL DÍA'),
          const SizedBox(height: 8),
          Text(
            '${overview.summary.totalCalories.toStringAsFixed(0)} / ${overview.goal.calories.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: caloriesProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 16),
          _MacroProgressRow(
            label: 'Proteína',
            current: overview.summary.totalProtein,
            goal: overview.goal.protein,
            suffix: 'g',
          ),
          const SizedBox(height: 10),
          _MacroProgressRow(
            label: 'Carbohidratos',
            current: overview.summary.totalCarbs,
            goal: overview.goal.carbs,
            suffix: 'g',
          ),
          const SizedBox(height: 10),
          _MacroProgressRow(
            label: 'Grasas',
            current: overview.summary.totalFats,
            goal: overview.goal.fats,
            suffix: 'g',
          ),
        ],
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String suffix;

  const _MacroProgressRow({
    required this.label,
    required this.current,
    required this.goal,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${current.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)}$suffix',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}

class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<NutritionLogEntry> logs;

  const _MealSection({required this.mealType, required this.logs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HunterPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealType.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              Text(
                'Sin registros.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...logs.map(
                (log) => _FoodLogTile(
                  log: log,
                  onDelete: () async {
                    final error = await ref
                        .read(nutritionControllerProvider.notifier)
                        .deleteLog(log.id);

                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final NutritionLogEntry log;
  final Future<void> Function() onDelete;

  const _FoodLogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(log.foodName),
      subtitle: Text(
        '${log.calories.toStringAsFixed(0)} kcal • '
        'P ${log.protein.toStringAsFixed(1)} • '
        'C ${log.carbs.toStringAsFixed(1)} • '
        'G ${log.fats.toStringAsFixed(1)}',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
