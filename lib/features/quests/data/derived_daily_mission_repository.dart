import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../domain/daily_mission.dart';
import '../domain/daily_mission_repository.dart';
import '../domain/weekly_quest_overview.dart';
import '../domain/weekly_quest_reward.dart';

/// Repositorio derivado de misiones diarias.
///
/// ¿Qué hace?
/// Calcula:
/// - misiones del día
/// - estado semanal del tablero
/// - reclamos persistentes diarios
/// - reclamos persistentes semanales
///
/// ¿Para qué sirve?
/// Para introducir quests persistentes con progresión semanal
/// sin agregar un motor complejo todavía.
class DerivedDailyMissionRepository implements DailyMissionRepository {
  final AppDatabase db;
  final HealthRepository healthRepository;

  DerivedDailyMissionRepository(this.db, {required this.healthRepository});

  @override
  Future<List<DailyMission>> getTodayMissions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayKey = _dateKey(today);

    try {
      await healthRepository.syncTodayToCache();
    } catch (_) {}

    final habits = await db.select(db.habits).get();

    final habitLogsToday = await (db.select(
      db.habitLogs,
    )..where((table) => table.dateKey.equals(todayKey))).get();

    final workoutsToday =
        await (db.select(db.workouts)..where(
              (table) =>
                  table.startedAt.isBiggerOrEqualValue(today) &
                  table.startedAt.isSmallerThanValue(tomorrow),
            ))
            .get();

    final nutritionLogsToday =
        await (db.select(db.nutritionLogs)..where(
              (table) =>
                  table.loggedAt.isBiggerOrEqualValue(today) &
                  table.loggedAt.isSmallerThanValue(tomorrow),
            ))
            .get();

    final claimsToday = await (db.select(
      db.dailyMissionClaims,
    )..where((table) => table.dateKey.equals(todayKey))).get();

    final claimedMissionIds = claimsToday
        .map((claim) => claim.missionId)
        .toSet();

    final healthDays = await healthRepository.getCachedDailyRecords(
      limitDays: 2,
    );
    final health = healthDays
        .where((record) => record.dateKey == todayKey)
        .cast<dynamic>()
        .firstWhere((_) => true, orElse: () => null);

    final completedHabitIds = habitLogsToday.map((log) => log.habitId).toSet();

    final breakfastLogs = nutritionLogsToday
        .where((log) => log.mealType == 'breakfast')
        .toList();

    final breakfastProtein = breakfastLogs.fold<double>(
      0,
      (sum, log) => sum + log.protein,
    );

    final finishedWorkoutToday = workoutsToday.any(
      (workout) => workout.endedAt != null,
    );

    final stepsToday = health?.steps ?? 0;
    final sleepTodayMinutes = health?.totalSleepMinutes ?? 0;

    final focusHabit = _findHabitByTokens(habits, const [
      'enfoque',
      'focus',
      'bloque',
      'pomodoro',
    ]);

    final noPhoneHabit = _findHabitByTokens(habits, const [
      'sin celular',
      'no celular',
      'no redes',
      'despertar sin celular',
    ]);

    final faceHabit = _findHabitByTokens(habits, const [
      'facial',
      'cara',
      'protector',
      'skin',
      'rostro',
      'grooming',
    ]);

    return <DailyMission>[
      _mission(
        id: 'wake_without_phone',
        title: 'Despertar de Hierro',
        description: 'Arranca el día sin tocar el celular al despertar.',
        category: DailyMissionCategory.discipline,
        xpReward: 20,
        currentProgress: _isHabitCompleted(noPhoneHabit, completedHabitIds)
            ? 1
            : 0,
        targetProgress: 1,
        isCompleted: _isHabitCompleted(noPhoneHabit, completedHabitIds),
        isAvailable: noPhoneHabit != null,
        unavailableReason: noPhoneHabit == null
            ? 'Crea un hábito tipo "despertar sin celular" para seguir esta misión.'
            : null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'hunter_breakfast',
        title: 'Desayuno del Cazador',
        description: 'Llega a 25 g de proteína en el desayuno.',
        category: DailyMissionCategory.nutrition,
        xpReward: 25,
        currentProgress: breakfastProtein.floor(),
        targetProgress: 25,
        isCompleted: breakfastProtein >= 25,
        isAvailable: true,
        unavailableReason: null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'movement_of_sanctuary',
        title: 'Movimiento del Santuario',
        description: 'Completa un entrenamiento hoy o alcanza 6000 pasos.',
        category: DailyMissionCategory.training,
        xpReward: 35,
        currentProgress: (finishedWorkoutToday || stepsToday >= 6000) ? 1 : 0,
        targetProgress: 1,
        isCompleted: finishedWorkoutToday || stepsToday >= 6000,
        isAvailable: true,
        unavailableReason: null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'mind_without_noise',
        title: 'Mente sin Ruido',
        description: 'Completa tu bloque de enfoque del día.',
        category: DailyMissionCategory.discipline,
        xpReward: 20,
        currentProgress: _isHabitCompleted(focusHabit, completedHabitIds)
            ? 1
            : 0,
        targetProgress: 1,
        isCompleted: _isHabitCompleted(focusHabit, completedHabitIds),
        isAvailable: focusHabit != null,
        unavailableReason: focusHabit == null
            ? 'Crea un hábito tipo "bloque de enfoque" para seguir esta misión.'
            : null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'face_ritual',
        title: 'Ritual del Rostro',
        description: 'Completa tu rutina facial o de grooming.',
        category: DailyMissionCategory.appearance,
        xpReward: 15,
        currentProgress: _isHabitCompleted(faceHabit, completedHabitIds)
            ? 1
            : 0,
        targetProgress: 1,
        isCompleted: _isHabitCompleted(faceHabit, completedHabitIds),
        isAvailable: faceHabit != null,
        unavailableReason: faceHabit == null
            ? 'Crea un hábito tipo "rutina facial" o "grooming" para seguir esta misión.'
            : null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'sleep_pact',
        title: 'Pacto del Sueño',
        description: 'Duerme al menos 7 horas.',
        category: DailyMissionCategory.recovery,
        xpReward: 30,
        currentProgress: sleepTodayMinutes,
        targetProgress: 420,
        isCompleted: sleepTodayMinutes >= 420,
        isAvailable: true,
        unavailableReason: null,
        claimedMissionIds: claimedMissionIds,
      ),
      _mission(
        id: 'order_of_day',
        title: 'Orden del Día',
        description: 'Completa al menos 2 hábitos hoy.',
        category: DailyMissionCategory.discipline,
        xpReward: 25,
        currentProgress: habitLogsToday.length,
        targetProgress: 2,
        isCompleted: habitLogsToday.length >= 2,
        isAvailable: true,
        unavailableReason: null,
        claimedMissionIds: claimedMissionIds,
      ),
    ];
  }

  @override
  Future<void> claimMission(String missionId) async {
    final missions = await getTodayMissions();

    final match = missions.where((mission) => mission.id == missionId).toList();
    if (match.isEmpty) {
      throw Exception('La misión solicitada no existe.');
    }

    final mission = match.first;

    if (!mission.isAvailable) {
      throw Exception('Esta misión no está disponible todavía.');
    }

    if (!mission.isCompleted) {
      throw Exception('Primero debes completar la misión antes de reclamarla.');
    }

    if (mission.isClaimed) {
      throw Exception('Esta misión ya fue reclamada hoy.');
    }

    final now = DateTime.now();
    final todayKey = _dateKey(DateTime(now.year, now.month, now.day));

    await db
        .into(db.dailyMissionClaims)
        .insert(
          DailyMissionClaimsCompanion.insert(
            dateKey: todayKey,
            missionId: mission.id,
            missionTitleSnapshot: mission.title,
            xpReward: mission.xpReward,
            claimedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<WeeklyQuestOverview> getCurrentWeekOverview() async {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final nextWeekStart = weekStart.add(const Duration(days: 7));

    final startKey = _dateKey(weekStart);
    final nextWeekKey = _dateKey(nextWeekStart);
    final weekKey = _weekKey(weekStart);

    final allDailyClaims = await db.select(db.dailyMissionClaims).get();
    final weeklyDailyClaims = allDailyClaims.where((claim) {
      return claim.dateKey.compareTo(startKey) >= 0 &&
          claim.dateKey.compareTo(nextWeekKey) < 0;
    }).toList();

    final weeklyRewardClaims = await (db.select(
      db.weeklyQuestRewardClaims,
    )..where((table) => table.weekKey.equals(weekKey))).get();

    final claimedRewardIds = weeklyRewardClaims
        .map((claim) => claim.rewardId)
        .toSet();

    final claimsByDate = <String, int>{};
    for (final claim in weeklyDailyClaims) {
      claimsByDate[claim.dateKey] = (claimsByDate[claim.dateKey] ?? 0) + 1;
    }

    final totalClaims = weeklyDailyClaims.length;
    final activeDays = claimsByDate.length;
    final fullBoardDays = claimsByDate.values
        .where((count) => count >= 7)
        .length;

    final rewards = <WeeklyQuestReward>[
      _weeklyReward(
        id: 'bronze_contract_cache',
        title: 'Arcón de Bronce',
        description: 'Reclama 7 misiones esta semana.',
        requiredClaims: 7,
        currentClaims: totalClaims,
        xpReward: 60,
        claimedRewardIds: claimedRewardIds,
      ),
      _weeklyReward(
        id: 'silver_contract_cache',
        title: 'Arcón de Plata',
        description: 'Reclama 14 misiones esta semana.',
        requiredClaims: 14,
        currentClaims: totalClaims,
        xpReward: 120,
        claimedRewardIds: claimedRewardIds,
      ),
      _weeklyReward(
        id: 'gold_contract_cache',
        title: 'Arcón Dorado',
        description: 'Reclama 21 misiones esta semana.',
        requiredClaims: 21,
        currentClaims: totalClaims,
        xpReward: 180,
        claimedRewardIds: claimedRewardIds,
      ),
      _weeklyReward(
        id: 'abyss_contract_cache',
        title: 'Arcón del Abismo',
        description: 'Reclama 35 misiones esta semana.',
        requiredClaims: 35,
        currentClaims: totalClaims,
        xpReward: 300,
        claimedRewardIds: claimedRewardIds,
      ),
    ];

    return WeeklyQuestOverview(
      weekKey: weekKey,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalClaims: totalClaims,
      maxClaims: 49,
      activeDays: activeDays,
      fullBoardDays: fullBoardDays,
      rewards: rewards,
    );
  }

  @override
  Future<void> claimWeeklyReward(String rewardId) async {
    final overview = await getCurrentWeekOverview();

    final match = overview.rewards
        .where((reward) => reward.id == rewardId)
        .toList();
    if (match.isEmpty) {
      throw Exception('La recompensa semanal solicitada no existe.');
    }

    final reward = match.first;

    if (!reward.isUnlocked) {
      throw Exception(
        'Aún no cumples el requisito para esta recompensa semanal.',
      );
    }

    if (reward.isClaimed) {
      throw Exception('Esta recompensa semanal ya fue reclamada.');
    }

    await db
        .into(db.weeklyQuestRewardClaims)
        .insert(
          WeeklyQuestRewardClaimsCompanion.insert(
            weekKey: overview.weekKey,
            rewardId: reward.id,
            rewardTitleSnapshot: reward.title,
            xpReward: reward.xpReward,
            claimedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  DailyMission _mission({
    required String id,
    required String title,
    required String description,
    required DailyMissionCategory category,
    required int xpReward,
    required int currentProgress,
    required int targetProgress,
    required bool isCompleted,
    required bool isAvailable,
    required String? unavailableReason,
    required Set<String> claimedMissionIds,
  }) {
    return DailyMission(
      id: id,
      title: title,
      description: description,
      category: category,
      xpReward: xpReward,
      currentProgress: currentProgress,
      targetProgress: targetProgress,
      isCompleted: isCompleted,
      isAvailable: isAvailable,
      unavailableReason: unavailableReason,
      isClaimed: claimedMissionIds.contains(id),
    );
  }

  WeeklyQuestReward _weeklyReward({
    required String id,
    required String title,
    required String description,
    required int requiredClaims,
    required int currentClaims,
    required int xpReward,
    required Set<String> claimedRewardIds,
  }) {
    return WeeklyQuestReward(
      id: id,
      title: title,
      description: description,
      requiredClaims: requiredClaims,
      currentClaims: currentClaims,
      xpReward: xpReward,
      isClaimed: claimedRewardIds.contains(id),
    );
  }

  Habit? _findHabitByTokens(List<Habit> habits, List<String> tokens) {
    for (final habit in habits) {
      final haystack = '${habit.name} ${habit.category}'.toLowerCase();

      for (final token in tokens) {
        if (haystack.contains(token.toLowerCase())) {
          return habit;
        }
      }
    }

    return null;
  }

  bool _isHabitCompleted(Habit? habit, Set<String> completedHabitIds) {
    if (habit == null) return false;
    return completedHabitIds.contains(habit.id);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final weekday = normalized.weekday;
    return normalized.subtract(Duration(days: weekday - DateTime.monday));
  }

  String _weekKey(DateTime weekStart) => _dateKey(weekStart);

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
