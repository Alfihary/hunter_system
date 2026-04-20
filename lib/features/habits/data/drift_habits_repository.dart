import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/habit_category.dart';
import '../domain/habit_dashboard.dart';
import '../domain/habit_history_entry.dart';
import '../domain/habit_summary.dart';
import '../domain/habits_overview.dart';
import '../domain/habits_repository.dart';

/// Implementación real del repositorio de hábitos usando Drift.
///
/// ¿Qué hace?
/// Lee y escribe hábitos y logs desde SQLite.
///
/// ¿Para qué sirve?
/// Para encapsular toda la persistencia local en un solo lugar.
class DriftHabitsRepository implements HabitsRepository {
  final AppDatabase db;

  DriftHabitsRepository(this.db);

  @override
  Future<HabitsOverview> getOverview({
    HabitCategory? filter,
  }) async {
    final query = db.select(db.habits)
      ..where((table) => table.isActive.equals(true));

    if (filter != null) {
      query.where((table) => table.category.equals(filter.name));
    }

    query.orderBy([
      (table) => OrderingTerm.asc(table.createdAt),
    ]);

    final habitRows = await query.get();

    if (habitRows.isEmpty) {
      return const HabitsOverview(
        dashboard: HabitDashboard(
          totalHabits: 0,
          completedToday: 0,
          xpEarnedToday: 0,
          xpEarnedOverall: 0,
        ),
        habits: [],
      );
    }

    final habitIds = habitRows.map((habit) => habit.id).toList();

    final logRows = await (db.select(db.habitLogs)
          ..where((table) => table.habitId.isIn(habitIds)))
        .get();

    final todayKey = _dateKey(DateTime.now());

    final xpByHabitId = <String, int>{
      for (final habit in habitRows) habit.id: habit.xpReward,
    };

    final summaries = habitRows.map((habit) {
      final logsForHabit =
          logRows.where((log) => log.habitId == habit.id).toList();

      final completedToday =
          logsForHabit.any((log) => log.dateKey == todayKey);

      final currentStreak = _calculateCurrentStreak(
        logsForHabit.map((log) => log.dateKey),
      );

      return HabitSummary(
        id: habit.id,
        name: habit.name,
        category: HabitCategory.fromStorage(habit.category),
        xpReward: habit.xpReward,
        completedToday: completedToday,
        currentStreak: currentStreak,
      );
    }).toList();

    final completedTodayCount =
        summaries.where((habit) => habit.completedToday).length;

    final xpEarnedToday = summaries
        .where((habit) => habit.completedToday)
        .fold<int>(0, (sum, habit) => sum + habit.xpReward);

    final xpEarnedOverall = logRows.fold<int>(0, (sum, log) {
      return sum + (xpByHabitId[log.habitId] ?? 0);
    });

    return HabitsOverview(
      dashboard: HabitDashboard(
        totalHabits: summaries.length,
        completedToday: completedTodayCount,
        xpEarnedToday: xpEarnedToday,
        xpEarnedOverall: xpEarnedOverall,
      ),
      habits: summaries,
    );
  }

  @override
  Future<List<HabitHistoryEntry>> getHabitHistory(
    String habitId, {
    int days = 14,
  }) async {
    final habit = await (db.select(db.habits)
          ..where((table) => table.id.equals(habitId)))
        .getSingleOrNull();

    if (habit == null) return [];

    final logs = await (db.select(db.habitLogs)
          ..where((table) => table.habitId.equals(habitId)))
        .get();

    final completedKeys = logs.map((log) => log.dateKey).toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(days, (index) {
      final date = today.subtract(Duration(days: index));
      final key = _dateKey(date);
      final completed = completedKeys.contains(key);

      return HabitHistoryEntry(
        date: date,
        completed: completed,
        xpEarned: completed ? habit.xpReward : 0,
      );
    });
  }

  @override
  Future<void> createHabit({
    required String name,
    required HabitCategory category,
    required int xpReward,
  }) async {
    final now = DateTime.now();

    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: now.microsecondsSinceEpoch.toString(),
            name: name.trim(),
            category: category.name,
            xpReward: Value(xpReward),
            createdAt: now,
          ),
        );
  }

@override
Future<void> updateHabit({
  required String id,
  required String name,
  required HabitCategory category,
  required int xpReward,
}) async {
  await (db.update(db.habits)..where((table) => table.id.equals(id))).write(
    HabitsCompanion(
      name: Value(name.trim()),
      category: Value(category.name),
      xpReward: Value(xpReward),
    ),
  );
}

  @override
  Future<void> toggleHabitForToday(String habitId) async {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    final existingLog = await (db.select(db.habitLogs)
          ..where((table) => table.habitId.equals(habitId))
          ..where((table) => table.dateKey.equals(todayKey)))
        .getSingleOrNull();

    if (existingLog != null) {
      await (db.delete(db.habitLogs)
            ..where((table) => table.id.equals(existingLog.id)))
          .go();
      return;
    }

    await db.into(db.habitLogs).insert(
          HabitLogsCompanion.insert(
            id: '${habitId}_$todayKey',
            habitId: habitId,
            dateKey: todayKey,
            completedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await (db.delete(db.habits)..where((table) => table.id.equals(habitId))).go();
  }

  /// Convierte una fecha a una clave diaria estable.
  ///
  /// ¿Para qué sirve?
  /// Para comparar días sin depender de horas, minutos o segundos.
  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  /// Calcula la racha actual.
  ///
  /// Regla:
  /// - si hoy no está completado, la racha es 0
  /// - si hoy sí está completado, cuenta hacia atrás hasta romper la secuencia
  int _calculateCurrentStreak(Iterable<String> dateKeys) {
    final uniqueKeys = dateKeys.toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;

    while (true) {
      final day = today.subtract(Duration(days: streak));
      final key = _dateKey(day);

      if (uniqueKeys.contains(key)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}