import 'nutrition_day_overview.dart';

/// Nivel del análisis nutricional diario.
enum NutritionAnalysisLevel { good, warning, danger }

/// Resultado del análisis nutricional del día.
///
/// ¿Qué hace?
/// Interpreta calorías y macros contra las metas configuradas.
///
/// ¿Para qué sirve?
/// Para dar feedback útil al usuario, no sólo números.
class NutritionDayAnalysis {
  final NutritionAnalysisLevel level;
  final String title;
  final String message;

  const NutritionDayAnalysis({
    required this.level,
    required this.title,
    required this.message,
  });
}

/// Analizador nutricional diario.
///
/// Mantiene la lógica fuera de la UI.
class NutritionDayAnalyzer {
  static NutritionDayAnalysis analyze(NutritionDayOverview overview) {
    final goal = overview.goal;
    final summary = overview.summary;

    final calorieRatio = goal.calories <= 0
        ? 0.0
        : summary.totalCalories / goal.calories;

    final proteinRatio = goal.protein <= 0
        ? 0.0
        : summary.totalProtein / goal.protein;

    final fatsRatio = goal.fats <= 0 ? 0.0 : summary.totalFats / goal.fats;

    if (overview.logs.isEmpty) {
      return const NutritionDayAnalysis(
        level: NutritionAnalysisLevel.warning,
        title: 'Sin registros todavía',
        message:
            'Registra tu primera comida para empezar a controlar tu alimentación.',
      );
    }

    if (calorieRatio > 1.15) {
      return const NutritionDayAnalysis(
        level: NutritionAnalysisLevel.danger,
        title: 'Calorías elevadas',
        message:
            'Ya superaste bastante tu meta. Cuida porciones, frituras, refrescos y snacks.',
      );
    }

    if (proteinRatio < 0.45 && calorieRatio > 0.45) {
      return const NutritionDayAnalysis(
        level: NutritionAnalysisLevel.warning,
        title: 'Proteína baja',
        message:
            'Prioriza pollo, huevo, atún, yogur griego, queso panela o carne magra en la siguiente comida.',
      );
    }

    if (fatsRatio > 1.10) {
      return const NutritionDayAnalysis(
        level: NutritionAnalysisLevel.warning,
        title: 'Grasas altas',
        message:
            'Hoy conviene moderar empanizados, frituras, aceites, nueces y quesos altos en grasa.',
      );
    }

    if (calorieRatio >= 0.75 && calorieRatio <= 1.05 && proteinRatio >= 0.75) {
      return const NutritionDayAnalysis(
        level: NutritionAnalysisLevel.good,
        title: 'Día bien encaminado',
        message:
            'Tus calorías y proteína van en buen rango. Mantén una cena ligera y alta en proteína.',
      );
    }

    return const NutritionDayAnalysis(
      level: NutritionAnalysisLevel.good,
      title: 'Progreso registrado',
      message:
          'Sigue registrando tus comidas para mejorar la precisión del día.',
    );
  }
}
