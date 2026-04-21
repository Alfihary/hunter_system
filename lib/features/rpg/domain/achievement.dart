import 'achievement_rarity.dart';

/// Logro derivado del sistema RPG.
///
/// ¿Qué hace?
/// Representa un objetivo desbloqueable basado en la actividad real del usuario.
///
/// ¿Para qué sirve?
/// Para mostrar progreso, estado de desbloqueo y rareza.
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementRarity rarity;
  final int currentProgress;
  final int targetProgress;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.currentProgress,
    required this.targetProgress,
    required this.isUnlocked,
  });

  /// Progreso visible limitado al objetivo.
  int get clampedProgress {
    if (currentProgress >= targetProgress) return targetProgress;
    return currentProgress;
  }

  /// Progreso normalizado entre 0 y 1.
  double get progress {
    if (targetProgress <= 0) return 0;
    return (clampedProgress / targetProgress).clamp(0, 1);
  }
}
