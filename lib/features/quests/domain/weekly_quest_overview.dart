import 'weekly_quest_reward.dart';

/// Vista semanal del tablero de quests.
///
/// ¿Qué hace?
/// Agrupa la información principal de la semana actual:
/// - rango de fechas
/// - cantidad de misiones reclamadas
/// - días activos con quests
/// - días con tablero completo
/// - recompensas semanales
///
/// ¿Para qué sirve?
/// Para que la UI tenga una sola fuente de verdad del progreso semanal.
class WeeklyQuestOverview {
  final String weekKey;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalClaims;
  final int maxClaims;
  final int activeDays;
  final int fullBoardDays;
  final List<WeeklyQuestReward> rewards;

  const WeeklyQuestOverview({
    required this.weekKey,
    required this.weekStart,
    required this.weekEnd,
    required this.totalClaims,
    required this.maxClaims,
    required this.activeDays,
    required this.fullBoardDays,
    required this.rewards,
  });

  /// Progreso global de la semana.
  double get progress {
    if (maxClaims <= 0) return 0;
    return (totalClaims / maxClaims).clamp(0, 1);
  }
}
