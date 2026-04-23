/// Categorías de misión diaria.
///
/// ¿Qué hace?
/// Agrupa misiones por tipo para darles mejor contexto visual.
///
/// ¿Para qué sirve?
/// Para ordenar la UI y dar una semántica más clara al sistema.
enum DailyMissionCategory {
  discipline,
  training,
  nutrition,
  recovery,
  appearance;

  /// Etiqueta amigable para la UI.
  String get label {
    switch (this) {
      case DailyMissionCategory.discipline:
        return 'Disciplina';
      case DailyMissionCategory.training:
        return 'Entrenamiento';
      case DailyMissionCategory.nutrition:
        return 'Nutrición';
      case DailyMissionCategory.recovery:
        return 'Recovery';
      case DailyMissionCategory.appearance:
        return 'Presencia';
    }
  }
}

/// Misión diaria derivada.
///
/// ¿Qué hace?
/// Representa una misión calculada con base en:
/// - hábitos
/// - entrenamiento
/// - nutrición
/// - health
///
/// ¿Para qué sirve?
/// Para mostrar objetivos claros del día y permitir reclamarlos
/// como recompensas persistentes.
class DailyMission {
  final String id;
  final String title;
  final String description;
  final DailyMissionCategory category;
  final int xpReward;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;

  /// Indica si la misión puede resolverse hoy con la configuración actual.
  final bool isAvailable;

  /// Mensaje de ayuda cuando la misión aún no puede resolverse.
  final String? unavailableReason;

  /// Indica si el usuario ya reclamó esta misión hoy.
  final bool isClaimed;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    required this.isAvailable,
    required this.unavailableReason,
    required this.isClaimed,
  });

  /// Indica si la misión puede reclamarse en este momento.
  bool get canClaim => isAvailable && isCompleted && !isClaimed;

  /// Progreso normalizado entre 0 y 1.
  double get progress {
    if (targetProgress <= 0) return 0;
    return (clampedProgress / targetProgress).clamp(0, 1);
  }

  /// Progreso limitado al objetivo.
  int get clampedProgress {
    if (currentProgress >= targetProgress) return targetProgress;
    return currentProgress;
  }

  /// Texto corto de progreso.
  String get progressLabel => '$clampedProgress / $targetProgress';
}
