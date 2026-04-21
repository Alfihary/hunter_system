import 'nutrition_source_type.dart';

/// Resultado de búsqueda de un alimento proveniente de una fuente externa.
///
/// ¿Qué hace?
/// Representa un alimento encontrado en una API remota,
/// ya transformado al formato que necesita la app.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la forma exacta en que responde la API.
/// La pantalla sólo necesita:
/// - nombre
/// - fuente
/// - macros
/// - calorías
/// - descripción de porción
/// - id externo
class NutritionSearchResult {
  final String externalId;
  final String foodName;
  final String? brandName;
  final String? servingDescription;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final NutritionSourceType sourceType;

  const NutritionSearchResult({
    required this.externalId,
    required this.foodName,
    required this.brandName,
    required this.servingDescription,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.sourceType,
  });

  /// Texto secundario útil para mostrar en listas.
  String get subtitle {
    final brandPart = brandName == null || brandName!.trim().isEmpty
        ? ''
        : '$brandName • ';
    final servingPart =
        servingDescription == null || servingDescription!.trim().isEmpty
        ? ''
        : '$servingDescription • ';

    return '$brandPart$servingPart'
        '${calories.toStringAsFixed(0)} kcal • '
        'P ${protein.toStringAsFixed(1)} • '
        'C ${carbs.toStringAsFixed(1)} • '
        'G ${fats.toStringAsFixed(1)}';
  }
}
