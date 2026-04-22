/// Resumen de sueño reciente.
///
/// ¿Qué hace?
/// Representa el sueño leído desde la plataforma de salud
/// dentro de una ventana reciente.
///
/// ¿Para qué sirve?
/// Para mostrar duración total dormida, desglose por etapas
/// y, más adelante, conectar este dato con recovery y balance del RPG.
class SleepDaySummary {
  final int totalMinutesAsleep;
  final int awakeMinutes;
  final int lightMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int sessionCount;
  final int goalSleepMinutes;

  const SleepDaySummary({
    required this.totalMinutesAsleep,
    required this.awakeMinutes,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.sessionCount,
    required this.goalSleepMinutes,
  });

  /// Indica si ya se alcanzó una meta mínima razonable de sueño.
  bool get goalReached => totalMinutesAsleep >= goalSleepMinutes;

  /// Duración total dormida en horas.
  double get totalHours => totalMinutesAsleep / 60.0;

  /// Progreso normalizado contra la meta.
  double get progress {
    if (goalSleepMinutes <= 0) return 0;
    return (totalMinutesAsleep / goalSleepMinutes).clamp(0, 1);
  }

  /// Devuelve true si existe al menos algo de sueño registrado.
  bool get hasSleepData => totalMinutesAsleep > 0 || sessionCount > 0;
}
