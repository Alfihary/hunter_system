/// Resumen principal del dashboard Home.
///
/// ¿Qué hace?
/// Agrupa en un solo objeto la información más importante del día:
/// - progreso RPG
/// - misión diaria
/// - actividad de hoy
/// - estado Health
/// - mensaje de prioridad
///
/// ¿Para qué sirve?
/// Para que la Home pueda renderizar un resumen completo del sistema
/// sin mezclar lógica de negocio dentro de la UI.
class HomeDashboardOverview {
  final DateTime generatedAt;

  final String rankLabel;
  final int level;
  final int totalXp;
  final int activeStreakDays;

  final String? equippedTitleName;
  final String? equippedTitleDescription;

  final int totalTodayMissions;
  final int completedTodayMissions;
  final int claimableTodayMissions;
  final int claimedTodayMissions;
  final int claimedTodayMissionXp;

  final int completedHabitsToday;
  final int finishedWorkoutsToday;
  final int nutritionLogsToday;

  final bool isHealthSupported;
  final bool hasHealthPermissions;
  final int stepsToday;
  final int stepGoal;
  final int sleepMinutesToday;
  final int sleepGoalMinutes;

  final String focusMessage;

  const HomeDashboardOverview({
    required this.generatedAt,
    required this.rankLabel,
    required this.level,
    required this.totalXp,
    required this.activeStreakDays,
    required this.equippedTitleName,
    required this.equippedTitleDescription,
    required this.totalTodayMissions,
    required this.completedTodayMissions,
    required this.claimableTodayMissions,
    required this.claimedTodayMissions,
    required this.claimedTodayMissionXp,
    required this.completedHabitsToday,
    required this.finishedWorkoutsToday,
    required this.nutritionLogsToday,
    required this.isHealthSupported,
    required this.hasHealthPermissions,
    required this.stepsToday,
    required this.stepGoal,
    required this.sleepMinutesToday,
    required this.sleepGoalMinutes,
    required this.focusMessage,
  });

  /// Progreso de misiones del día.
  double get missionProgress {
    if (totalTodayMissions <= 0) return 0;
    return (completedTodayMissions / totalTodayMissions).clamp(0.0, 1.0);
  }

  /// Progreso de pasos.
  double get stepsProgress {
    if (stepGoal <= 0) return 0;
    return (stepsToday / stepGoal).clamp(0.0, 1.0);
  }

  /// Progreso de sueño.
  double get sleepProgress {
    if (sleepGoalMinutes <= 0) return 0;
    return (sleepMinutesToday / sleepGoalMinutes).clamp(0.0, 1.0);
  }

  /// Horas dormidas visibles para la UI.
  double get sleepHours => sleepMinutesToday / 60.0;

  /// Indica si existe título equipado.
  bool get hasEquippedTitle =>
      equippedTitleName != null && equippedTitleName!.trim().isNotEmpty;
}
