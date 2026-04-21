/// Metas nutricionales diarias.
///
/// ¿Qué hace?
/// Representa los objetivos diarios del usuario.
///
/// ¿Para qué sirve?
/// Para comparar el consumo actual del día contra una meta concreta.
class NutritionGoal {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  const NutritionGoal({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}
