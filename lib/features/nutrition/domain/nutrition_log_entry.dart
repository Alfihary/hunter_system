import 'meal_type.dart';
import 'nutrition_source_type.dart';

/// Registro individual de un alimento o comida.
///
/// ¿Qué hace?
/// Guarda el snapshot nutricional exacto del alimento
/// en el momento en que se registró.
///
/// ¿Para qué sirve?
/// Para que el historial no dependa de cambios futuros en APIs externas
/// o catálogos de alimentos.
class NutritionLogEntry {
  final String id;
  final String foodName;
  final MealType mealType;
  final NutritionSourceType sourceType;
  final String? servingDescription;
  final String? externalId;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime loggedAt;

  const NutritionLogEntry({
    required this.id,
    required this.foodName,
    required this.mealType,
    required this.sourceType,
    required this.servingDescription,
    required this.externalId,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.loggedAt,
  });
}
