import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/meal_type.dart';
import '../../domain/nutrition_day_overview.dart';
import '../../domain/nutrition_log_entry.dart';
import '../providers/nutrition_controller.dart';

/// Pantalla principal de nutrición.
///
/// ¿Qué hace?
/// - muestra resumen del día
/// - muestra metas
/// - lista los alimentos del día
/// - permite cambiar de fecha
/// - permite editar metas
/// - permite crear registros manuales, buscar por API o escanear barcode
///
/// ¿Para qué sirve?
/// Es el punto de entrada del módulo de nutrición.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(nutritionControllerProvider);
    final selectedDate = ref.watch(selectedNutritionDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrición'),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DateSelector(
                selectedDate: selectedDate,
                onPrevious: () {
                  ref
                      .read(selectedNutritionDateProvider.notifier)
                      .goToPreviousDay();
                },
                onToday: () {
                  ref.read(selectedNutritionDateProvider.notifier).goToToday();
                },
                onNext: () {
                  ref
                      .read(selectedNutritionDateProvider.notifier)
                      .goToNextDay();
                },
              ),
              const SizedBox(height: 12),
              _SummaryCard(overview: overview),
              const SizedBox(height: 12),
              ...sortedMealTypes.map<Widget>(
                (mealType) => _MealSection(
                  mealType: mealType,
                  logs: overview.logsForMeal(mealType),
                ),
              ),
            ],
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
                TextField(
                  controller: caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Calorías'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Proteína'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Carbohidratos'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Grasas'),
                ),
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

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  const _DateSelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onToday, child: const Text('Hoy')),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final NutritionDayOverview overview;

  const _SummaryCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              'Resumen del día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _MacroProgressRow(
              label: 'Calorías',
              current: overview.summary.totalCalories,
              goal: overview.goal.calories,
            ),
            const SizedBox(height: 8),
            _MacroProgressRow(
              label: 'Proteína',
              current: overview.summary.totalProtein,
              goal: overview.goal.protein,
            ),
            const SizedBox(height: 8),
            _MacroProgressRow(
              label: 'Carbohidratos',
              current: overview.summary.totalCarbs,
              goal: overview.goal.carbs,
            ),
            const SizedBox(height: 8),
            _MacroProgressRow(
              label: 'Grasas',
              current: overview.summary.totalFats,
              goal: overview.goal.fats,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double goal;

  const _MacroProgressRow({
    required this.label,
    required this.current,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${current.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)}',
        ),
        const SizedBox(height: 4),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
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
              const Text('Sin registros.')
            else
              ...logs.map(
                (log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(log.foodName),
                  subtitle: Text(
                    '${log.calories.toStringAsFixed(0)} kcal • P ${log.protein.toStringAsFixed(1)} • C ${log.carbs.toStringAsFixed(1)} • G ${log.fats.toStringAsFixed(1)}',
                  ),
                  trailing: IconButton(
                    onPressed: () async {
                      final error = await ref
                          .read(nutritionControllerProvider.notifier)
                          .deleteLog(log.id);

                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
