/// Resumen diario de pasos.
///
/// ¿Qué hace?
/// Representa el total de pasos del día y su avance contra una meta.
///
/// ¿Para qué sirve?
/// Para mostrar actividad diaria y, más adelante,
/// conectar este dato con el sistema RPG.
class DailyStepsSummary {
  final int steps;
  final int goalSteps;

  const DailyStepsSummary({required this.steps, required this.goalSteps});

  /// Indica si ya se alcanzó la meta diaria.
  bool get goalReached => steps >= goalSteps;

  /// Pasos restantes para llegar a la meta.
  int get remainingSteps {
    final remaining = goalSteps - steps;
    return remaining > 0 ? remaining : 0;
  }

  /// Progreso normalizado entre 0 y 1.
  double get progress {
    if (goalSteps <= 0) return 0;
    return (steps / goalSteps).clamp(0, 1);
  }
}
