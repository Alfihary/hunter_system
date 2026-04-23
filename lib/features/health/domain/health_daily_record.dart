/// Snapshot diario de datos de salud.
///
/// ¿Qué hace?
/// Guarda una fotografía diaria de:
/// - pasos
/// - sueño total
/// - etapas de sueño
/// - metas usadas ese día
///
/// ¿Para qué sirve?
/// Para poder conectar Health al RPG de forma estable,
/// sin depender sólo del dato "en vivo" del dispositivo.
class HealthDailyRecord {
  final String dateKey;
  final int steps;
  final int goalSteps;
  final int totalSleepMinutes;
  final int goalSleepMinutes;
  final int awakeMinutes;
  final int lightMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int sessionCount;
  final DateTime syncedAt;

  const HealthDailyRecord({
    required this.dateKey,
    required this.steps,
    required this.goalSteps,
    required this.totalSleepMinutes,
    required this.goalSleepMinutes,
    required this.awakeMinutes,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.sessionCount,
    required this.syncedAt,
  });

  /// Indica si se cumplió la meta diaria de pasos.
  bool get stepsGoalReached => steps >= goalSteps;

  /// Indica si se cumplió la meta diaria de sueño.
  bool get sleepGoalReached => totalSleepMinutes >= goalSleepMinutes;
}
