import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../../quests/domain/daily_mission_repository.dart';
import '../../rpg/domain/rpg_repository.dart';
import '../domain/home_dashboard_overview.dart';

/// Repositorio del dashboard principal.
///
/// ¿Qué hace?
/// Consulta y combina información de varios módulos:
/// - hábitos
/// - entrenamiento
/// - nutrición
/// - health
/// - misiones
/// - RPG
///
/// ¿Para qué sirve?
/// Para centralizar la lógica del Home premium en un solo lugar
/// y mantener la UI limpia.
class HomeDashboardRepository {
  final AppDatabase db;
  final RpgRepository rpgRepository;
  final DailyMissionRepository dailyMissionRepository;
  final HealthRepository healthRepository;

  const HomeDashboardRepository({
    required this.db,
    required this.rpgRepository,
    required this.dailyMissionRepository,
    required this.healthRepository,
  });

  /// Obtiene el resumen completo del dashboard Home.
  Future<HomeDashboardOverview> getOverview() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayKey = _dateKey(today);

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

    final rpgOverview = await rpgRepository.getOverview();
    final titles = await rpgRepository.getTitles();
    final missions = await dailyMissionRepository.getTodayMissions();

    final equippedTitle = titles.where((title) => title.isEquipped).toList();
    final equipped = equippedTitle.isNotEmpty ? equippedTitle.first : null;

    bool isHealthSupported = false;
    bool hasHealthPermissions = false;
    int stepsToday = 0;
    int stepGoal = 8000;
    int sleepMinutesToday = 0;
    int sleepGoalMinutes = 420;

    try {
      final healthOverview = await healthRepository.getTodayOverview();
      isHealthSupported = healthOverview.isSupportedPlatform;
      hasHealthPermissions = healthOverview.hasPermissions;
      stepsToday = healthOverview.steps.steps;
      stepGoal = healthOverview.steps.goalSteps;
      sleepMinutesToday = healthOverview.sleep.totalMinutesAsleep;
      sleepGoalMinutes = healthOverview.sleep.goalSleepMinutes;
    } catch (_) {
      /// No rompemos Home si Health falla.
      isHealthSupported = false;
      hasHealthPermissions = false;
    }

    final completedTodayMissions = missions
        .where((mission) => mission.isCompleted)
        .length;

    final claimableTodayMissions = missions
        .where((mission) => mission.canClaim)
        .length;

    final claimedTodayMissions = missions
        .where((mission) => mission.isClaimed)
        .length;

    final claimedTodayMissionXp = missions
        .where((mission) => mission.isClaimed)
        .fold<int>(0, (sum, mission) => sum + mission.xpReward);

    return HomeDashboardOverview(
      generatedAt: now,
      rankLabel: rpgOverview.rank.label,
      level: rpgOverview.level,
      totalXp: rpgOverview.totalXp,
      activeStreakDays: rpgOverview.activeStreakDays,
      equippedTitleName: equipped?.name,
      equippedTitleDescription: equipped?.description,
      totalTodayMissions: missions.length,
      completedTodayMissions: completedTodayMissions,
      claimableTodayMissions: claimableTodayMissions,
      claimedTodayMissions: claimedTodayMissions,
      claimedTodayMissionXp: claimedTodayMissionXp,
      completedHabitsToday: habitLogsToday.length,
      finishedWorkoutsToday: workoutsToday
          .where((workout) => workout.endedAt != null)
          .length,
      nutritionLogsToday: nutritionLogsToday.length,
      isHealthSupported: isHealthSupported,
      hasHealthPermissions: hasHealthPermissions,
      stepsToday: stepsToday,
      stepGoal: stepGoal,
      sleepMinutesToday: sleepMinutesToday,
      sleepGoalMinutes: sleepGoalMinutes,
      focusMessage: _buildFocusMessage(
        claimableTodayMissions: claimableTodayMissions,
        completedTodayMissions: completedTodayMissions,
        totalTodayMissions: missions.length,
        finishedWorkoutsToday: workoutsToday
            .where((workout) => workout.endedAt != null)
            .length,
        nutritionLogsToday: nutritionLogsToday.length,
        stepsToday: stepsToday,
        sleepMinutesToday: sleepMinutesToday,
        isHealthSupported: isHealthSupported,
        hasHealthPermissions: hasHealthPermissions,
      ),
    );
  }

  /// Genera un mensaje de prioridad automática para el día.
  ///
  /// ¿Qué hace?
  /// Detecta la necesidad más clara del sistema actual.
  ///
  /// ¿Para qué sirve?
  /// Para que el usuario sepa cuál debería ser su siguiente acción.
  String _buildFocusMessage({
    required int claimableTodayMissions,
    required int completedTodayMissions,
    required int totalTodayMissions,
    required int finishedWorkoutsToday,
    required int nutritionLogsToday,
    required int stepsToday,
    required int sleepMinutesToday,
    required bool isHealthSupported,
    required bool hasHealthPermissions,
  }) {
    if (claimableTodayMissions > 0) {
      return 'Tienes $claimableTodayMissions misión(es) listas para reclamar.';
    }

    if (totalTodayMissions > 0 && completedTodayMissions == 0) {
      return 'Tu tablero de hoy todavía está frío. Empieza por hábitos o desayuno.';
    }

    if (finishedWorkoutsToday <= 0 && stepsToday < 6000) {
      return 'Activa tu progreso físico: entrena hoy o alcanza al menos 6000 pasos.';
    }

    if (nutritionLogsToday <= 0) {
      return 'Registra tu nutrición para alimentar el progreso real del RPG.';
    }

    if (isHealthSupported && hasHealthPermissions && sleepMinutesToday < 420) {
      return 'No descuides recovery: busca cerrar el día con 7 horas de sueño.';
    }

    if (isHealthSupported && hasHealthPermissions && stepsToday < 8000) {
      return 'Vas bien, pero todavía puedes empujar tu Health con más pasos.';
    }

    return 'Buen avance hoy. Consolida el tablero y sigue sumando XP real.';
  }

  /// Convierte fecha a YYYY-MM-DD.
  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
