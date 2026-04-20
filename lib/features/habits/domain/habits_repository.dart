import 'habit_category.dart';
import 'habit_history_entry.dart';
import 'habits_overview.dart';

/// Contrato del módulo de hábitos.
///
/// ¿Qué hace?
/// Define todas las operaciones disponibles para esta feature.
///
/// ¿Para qué sirve?
/// Para mantener desacoplada la UI de la implementación concreta con Drift.
abstract class HabitsRepository {
  Future<HabitsOverview> getOverview({
    HabitCategory? filter,
  });

  Future<List<HabitHistoryEntry>> getHabitHistory(
    String habitId, {
    int days = 14,
  });

  Future<void> createHabit({
    required String name,
    required HabitCategory category,
    required int xpReward,
  });

  Future<void> updateHabit({
    required String id,
    required String name,
    required HabitCategory category,
    required int xpReward,
  });

  Future<void> toggleHabitForToday(String habitId);

  Future<void> deleteHabit(String habitId);
}