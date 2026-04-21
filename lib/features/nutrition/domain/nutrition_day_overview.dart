import 'daily_nutrition_summary.dart';
import 'meal_type.dart';
import 'nutrition_goal.dart';
import 'nutrition_log_entry.dart';

/// Vista agregada de nutrición para una fecha concreta.
///
/// ¿Qué hace?
/// Une en un solo modelo:
/// - fecha
/// - metas
/// - resumen total
/// - lista de registros del día
///
/// ¿Para qué sirve?
/// Para que la pantalla principal de nutrición pinte todo
/// sin tener que combinar múltiples estados por su cuenta.
class NutritionDayOverview {
  final DateTime date;
  final NutritionGoal goal;
  final DailyNutritionSummary summary;
  final List<NutritionLogEntry> logs;

  const NutritionDayOverview({
    required this.date,
    required this.goal,
    required this.summary,
    required this.logs,
  });

  /// Devuelve los registros filtrados por tipo de comida.
  List<NutritionLogEntry> logsForMeal(MealType mealType) {
    return logs.where((log) => log.mealType == mealType).toList();
  }
}
