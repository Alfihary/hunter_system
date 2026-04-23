/// Desglose del XP total por módulos del sistema.
///
/// ¿Qué hace?
/// Separa el XP que viene de:
/// - hábitos
/// - entrenamiento
/// - nutrición
/// - health
/// - misiones
///
/// ¿Para qué sirve?
/// Para que el usuario entienda claramente
/// de dónde sale su progreso.
class RpgSourceBreakdown {
  final int habitsXp;
  final int workoutsXp;
  final int nutritionXp;
  final int healthXp;
  final int questsXp;

  const RpgSourceBreakdown({
    required this.habitsXp,
    required this.workoutsXp,
    required this.nutritionXp,
    required this.healthXp,
    required this.questsXp,
  });

  /// XP total sumado entre todas las fuentes.
  int get totalXp => habitsXp + workoutsXp + nutritionXp + healthXp + questsXp;
}
