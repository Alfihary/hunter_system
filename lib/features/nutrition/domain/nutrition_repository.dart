import 'nutrition_day_overview.dart';
import 'nutrition_search_result.dart';
import 'nutrition_source_type.dart';
import 'meal_type.dart';

/// Contrato del módulo de nutrición.
///
/// ¿Qué hace?
/// Define las operaciones principales del sistema de nutrición.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la implementación concreta con Drift
/// y de las integraciones remotas con APIs.
abstract class NutritionRepository {
  Future<NutritionDayOverview> getDayOverview(DateTime date);

  /// Busca alimentos por texto en una API remota.
  Future<List<NutritionSearchResult>> searchFoods(String query);

  /// Busca un producto por código de barras en una API remota.
  Future<NutritionSearchResult?> getFoodByBarcode(String barcode);

  Future<void> createLog({
    required DateTime loggedAt,
    required String foodName,
    required MealType mealType,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
    String? servingDescription,
    NutritionSourceType sourceType = NutritionSourceType.manual,
    String? externalId,
  });

  Future<void> deleteLog(String logId);

  Future<void> updateGoals({
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  });
}
