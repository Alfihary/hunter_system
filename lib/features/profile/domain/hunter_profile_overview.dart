import '../../rpg/domain/rpg_stats.dart';

/// Resumen completo del perfil del cazador.
///
/// ¿Qué hace?
/// Agrupa en un solo objeto la información más importante del perfil:
/// - progreso RPG
/// - stats
/// - título equipado
/// - progreso semanal
/// - estado Health
/// - logros destacados
/// - conteos globales del sistema
///
/// ¿Para qué sirve?
/// Para que la pantalla de perfil pueda renderizarse sin lógica de negocio
/// dentro de la UI.
class HunterProfileOverview {
  final DateTime generatedAt;

  final String rankLabel;
  final int level;
  final int totalXp;
  final int activeStreakDays;

  final String? equippedTitleName;
  final String? equippedTitleDescription;

  final RpgStats stats;

  final int unlockedAchievements;
  final int totalAchievements;
  final List<String> featuredAchievementNames;

  final int weekClaims;
  final int weekMaxClaims;
  final int weekActiveDays;
  final int weekFullBoardDays;

  final bool isHealthSupported;
  final bool hasHealthPermissions;
  final int stepsToday;
  final int stepGoal;
  final int sleepMinutesToday;
  final int sleepGoalMinutes;

  final int habitsCount;
  final int habitLogsCount;
  final int routineCount;
  final int finishedWorkoutsCount;
  final int nutritionLogsCount;
  final int dailyMissionClaimsCount;
  final int weeklyRewardClaimsCount;

  const HunterProfileOverview({
    required this.generatedAt,
    required this.rankLabel,
    required this.level,
    required this.totalXp,
    required this.activeStreakDays,
    required this.equippedTitleName,
    required this.equippedTitleDescription,
    required this.stats,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.featuredAchievementNames,
    required this.weekClaims,
    required this.weekMaxClaims,
    required this.weekActiveDays,
    required this.weekFullBoardDays,
    required this.isHealthSupported,
    required this.hasHealthPermissions,
    required this.stepsToday,
    required this.stepGoal,
    required this.sleepMinutesToday,
    required this.sleepGoalMinutes,
    required this.habitsCount,
    required this.habitLogsCount,
    required this.routineCount,
    required this.finishedWorkoutsCount,
    required this.nutritionLogsCount,
    required this.dailyMissionClaimsCount,
    required this.weeklyRewardClaimsCount,
  });

  /// Indica si el usuario tiene un título equipado visible.
  bool get hasEquippedTitle =>
      equippedTitleName != null && equippedTitleName!.trim().isNotEmpty;

  /// Progreso semanal normalizado.
  double get weekProgress {
    if (weekMaxClaims <= 0) return 0;
    return (weekClaims / weekMaxClaims).clamp(0.0, 1.0);
  }

  /// Progreso de pasos normalizado.
  double get stepsProgress {
    if (stepGoal <= 0) return 0;
    return (stepsToday / stepGoal).clamp(0.0, 1.0);
  }

  /// Progreso de sueño normalizado.
  double get sleepProgress {
    if (sleepGoalMinutes <= 0) return 0;
    return (sleepMinutesToday / sleepGoalMinutes).clamp(0.0, 1.0);
  }

  /// Horas de sueño visibles para UI.
  double get sleepHours => sleepMinutesToday / 60.0;
}
