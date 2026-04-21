/// Resumen nutricional acumulado del día.
///
/// ¿Qué hace?
/// Suma los macronutrientes y calorías del día actual.
///
/// ¿Para qué sirve?
/// Para mostrar progreso y adherencia nutricional diaria.
class DailyNutritionSummary {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;

  const DailyNutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
  });
}
