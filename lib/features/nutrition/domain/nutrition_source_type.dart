/// Fuente del alimento registrado.
///
/// ¿Qué hace?
/// Indica de dónde proviene la información nutricional del alimento.
///
/// ¿Para qué sirve?
/// Para dejar el módulo preparado para integración con APIs externas
/// sin romper el historial local.
///
/// Ejemplos:
/// - manual: capturado directamente por el usuario
/// - fdc: USDA FoodData Central
/// - openFoodFacts: Open Food Facts
enum NutritionSourceType {
  manual,
  fdc,
  openFoodFacts;

  String get label {
    switch (this) {
      case NutritionSourceType.manual:
        return 'Manual';
      case NutritionSourceType.fdc:
        return 'FoodData Central';
      case NutritionSourceType.openFoodFacts:
        return 'Open Food Facts';
    }
  }

  static NutritionSourceType fromStorage(String rawValue) {
    return NutritionSourceType.values.firstWhere(
      (value) => value.name == rawValue,
      orElse: () => NutritionSourceType.manual,
    );
  }
}
