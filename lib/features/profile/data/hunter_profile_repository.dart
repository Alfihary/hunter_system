import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../../quests/domain/daily_mission_repository.dart';
import '../../profile/domain/hunter_profile_overview.dart';
import '../../rpg/domain/rpg_repository.dart';

/// Repositorio del perfil del cazador.
///
/// ¿Qué hace?
/// Combina información de:
/// - RPG
/// - logros
/// - títulos
/// - quests
/// - health
/// - conteos reales de base de datos
///
/// ¿Para qué sirve?
/// Para centralizar toda la lógica del perfil en un solo punto.
class HunterProfileRepository {
  final AppDatabase db;
  final RpgRepository rpgRepository;
  final DailyMissionRepository dailyMissionRepository;
  final HealthRepository healthRepository;

  const HunterProfileRepository({
    required this.db,
    required this.rpgRepository,
    required this.dailyMissionRepository,
    required this.healthRepository,
  });

  /// Obtiene el overview completo del perfil.
  Future<HunterProfileOverview> getOverview() async {
    final now = DateTime.now();

    final rpgOverview = await rpgRepository.getOverview();
    final titles = await rpgRepository.getTitles();
    final achievements = await rpgRepository.getAchievements();
    final weeklyOverview = await dailyMissionRepository
        .getCurrentWeekOverview();

    final equippedTitles = titles.where((title) => title.isEquipped).toList();
    final equippedTitle = equippedTitles.isNotEmpty
        ? equippedTitles.first
        : null;

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
      isHealthSupported = false;
      hasHealthPermissions = false;
    }

    final unlockedAchievements =
        achievements.where((achievement) => achievement.isUnlocked).toList()
          ..sort((a, b) => b.rarity.sortOrder.compareTo(a.rarity.sortOrder));

    final featuredAchievementNames = unlockedAchievements
        .take(3)
        .map((achievement) => achievement.name)
        .toList();

    final habitsCount = await _count('habits');
    final habitLogsCount = await _count('habit_logs');
    final routineCount = await _count('workout_routines');
    final finishedWorkoutsCount = await _countWhere(
      tableName: 'workouts',
      whereClause: 'ended_at IS NOT NULL',
    );
    final nutritionLogsCount = await _count('nutrition_logs');
    final dailyMissionClaimsCount = await _count('daily_mission_claims');
    final weeklyRewardClaimsCount = await _count('weekly_quest_reward_claims');

    return HunterProfileOverview(
      generatedAt: now,
      rankLabel: rpgOverview.rank.label,
      level: rpgOverview.level,
      totalXp: rpgOverview.totalXp,
      activeStreakDays: rpgOverview.activeStreakDays,
      equippedTitleName: equippedTitle?.name,
      equippedTitleDescription: equippedTitle?.description,
      stats: rpgOverview.stats,
      unlockedAchievements: unlockedAchievements.length,
      totalAchievements: achievements.length,
      featuredAchievementNames: featuredAchievementNames,
      weekClaims: weeklyOverview.totalClaims,
      weekMaxClaims: weeklyOverview.maxClaims,
      weekActiveDays: weeklyOverview.activeDays,
      weekFullBoardDays: weeklyOverview.fullBoardDays,
      isHealthSupported: isHealthSupported,
      hasHealthPermissions: hasHealthPermissions,
      stepsToday: stepsToday,
      stepGoal: stepGoal,
      sleepMinutesToday: sleepMinutesToday,
      sleepGoalMinutes: sleepGoalMinutes,
      habitsCount: habitsCount,
      habitLogsCount: habitLogsCount,
      routineCount: routineCount,
      finishedWorkoutsCount: finishedWorkoutsCount,
      nutritionLogsCount: nutritionLogsCount,
      dailyMissionClaimsCount: dailyMissionClaimsCount,
      weeklyRewardClaimsCount: weeklyRewardClaimsCount,
    );
  }

  /// Cuenta filas de una tabla.
  Future<int> _count(String tableName) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS count FROM $tableName')
        .getSingle();

    return _readInt(row.data['count']);
  }

  /// Cuenta filas con condición.
  Future<int> _countWhere({
    required String tableName,
    required String whereClause,
  }) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM $tableName WHERE $whereClause',
        )
        .getSingle();

    return _readInt(row.data['count']);
  }

  /// Convierte dinámicos a int de forma segura.
  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
