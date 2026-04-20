import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_habits_repository.dart';
import '../../domain/habit_category.dart';
import '../../domain/habit_history_entry.dart';
import '../../domain/habit_summary.dart';
import '../../domain/habits_overview.dart';
import '../../domain/habits_repository.dart';

/// Provider del repositorio de hábitos.
///
/// ¿Qué hace?
/// Inyecta la implementación Drift en la capa de presentación.
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftHabitsRepository(db);
});

/// Controlador del filtro de categoría.
///
/// ¿Qué hace?
/// Guarda la categoría seleccionada actualmente.
///
/// ¿Para qué sirve?
/// Para no mezclar el filtro dentro del widget.
class HabitCategoryFilterController extends Notifier<HabitCategory?> {
  @override
  HabitCategory? build() => null;

  void setFilter(HabitCategory? category) {
    state = category;
  }

  void clear() {
    state = null;
  }
}

final selectedHabitCategoryFilterProvider =
    NotifierProvider<HabitCategoryFilterController, HabitCategory?>(
  HabitCategoryFilterController.new,
);

/// Controlador asíncrono del módulo de hábitos.
///
/// ¿Qué hace?
/// - carga overview
/// - crea hábitos
/// - actualiza hábitos
/// - alterna completado de hoy
/// - elimina hábitos
///
/// ¿Para qué sirve?
/// Para que la UI se mantenga declarativa y simple.
class HabitsController extends AsyncNotifier<HabitsOverview> {
  late final HabitsRepository _repository;

  @override
  Future<HabitsOverview> build() async {
    _repository = ref.watch(habitsRepositoryProvider);
    final filter = ref.watch(selectedHabitCategoryFilterProvider);

    return _repository.getOverview(filter: filter);
  }

  Future<String?> createHabit({
    required String name,
    required HabitCategory category,
    required int xpReward,
  }) async {
    try {
      await _repository.createHabit(
        name: name,
        category: category,
        xpReward: xpReward,
      );

      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> updateHabit({
    required String id,
    required String name,
    required HabitCategory category,
    required int xpReward,
  }) async {
    try {
      await _repository.updateHabit(
        id: id,
        name: name,
        category: category,
        xpReward: xpReward,
      );

      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> toggleHabitForToday(String habitId) async {
    try {
      await _repository.toggleHabitForToday(habitId);
      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<void> reload() async {
    final filter = ref.read(selectedHabitCategoryFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getOverview(filter: filter),
    );
  }
}

final habitsControllerProvider =
    AsyncNotifierProvider<HabitsController, HabitsOverview>(
  HabitsController.new,
);

/// Provider para obtener un hábito concreto desde el estado ya cargado.
///
/// ¿Qué hace?
/// Busca el hábito actual por ID dentro del overview.
///
/// ¿Para qué sirve?
/// Para que la pantalla de historial tenga siempre el dato más actualizado.
final currentHabitSummaryProvider = Provider.family<HabitSummary?, String>(
  (ref, habitId) {
    final overview = ref.watch(habitsControllerProvider).value;
    if (overview == null) return null;

    for (final habit in overview.habits) {
      if (habit.id == habitId) return habit;
    }

    return null;
  },
);

/// Provider de historial de un hábito.
///
/// ¿Qué hace?
/// Carga los últimos días del hábito seleccionado.
///
/// ¿Para qué sirve?
/// Para desacoplar la pantalla de historial del controlador principal.
final habitHistoryProvider =
    FutureProvider.family<List<HabitHistoryEntry>, String>(
  (ref, habitId) {
    final repository = ref.watch(habitsRepositoryProvider);
    return repository.getHabitHistory(habitId, days: 14);
  },
);