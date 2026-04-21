/// Desglose del XP total por módulos del sistema.
///
/// ¿Qué hace?
/// Separa el XP que viene de:
/// - hábitos
/// - entrenamiento
/// - nutrición
///
/// ¿Para qué sirve?
/// Para que el usuario entienda claramente
/// de dónde sale su progreso.
class RpgSourceBreakdown {
  final int habitsXp;
  final int workoutsXp;
  final int nutritionXp;

  const RpgSourceBreakdown({
    required this.habitsXp,
    required this.workoutsXp,
    required this.nutritionXp,
  });

  /// XP total sumado entre todas las fuentes.
  int get totalXp => habitsXp + workoutsXp + nutritionXp;
}