/// Recompensa semanal del tablero de quests.
///
/// ¿Qué hace?
/// Representa un premio desbloqueable por acumular misiones
/// reclamadas dentro de la semana actual.
///
/// ¿Para qué sirve?
/// Para convertir el sistema diario en una progresión semanal real.
class WeeklyQuestReward {
  final String id;
  final String title;
  final String description;
  final int requiredClaims;
  final int currentClaims;
  final int xpReward;
  final bool isClaimed;

  const WeeklyQuestReward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredClaims,
    required this.currentClaims,
    required this.xpReward,
    required this.isClaimed,
  });

  /// Indica si ya se alcanzó el requisito de quests reclamadas.
  bool get isUnlocked => currentClaims >= requiredClaims;

  /// Indica si la recompensa puede reclamarse ahora.
  bool get canClaim => isUnlocked && !isClaimed;

  /// Progreso limitado al objetivo.
  int get clampedProgress {
    if (currentClaims >= requiredClaims) return requiredClaims;
    return currentClaims;
  }

  /// Progreso normalizado.
  double get progress {
    if (requiredClaims <= 0) return 0;
    return (clampedProgress / requiredClaims).clamp(0, 1);
  }

  /// Texto corto de progreso.
  String get progressLabel => '$clampedProgress / $requiredClaims';
}
