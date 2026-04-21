import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' hide NutritionGoal;
import '../domain/daily_nutrition_summary.dart';
import '../domain/meal_type.dart';
import '../domain/nutrition_day_overview.dart';
import '../domain/nutrition_goal.dart' as domain;
import '../domain/nutrition_log_entry.dart';
import '../domain/nutrition_repository.dart';
import '../domain/nutrition_search_result.dart';
import '../domain/nutrition_source_type.dart';
import 'remote/food_data_central_api_client.dart';
import 'remote/open_food_facts_api_client.dart';

/// Implementación real del módulo de nutrición usando Drift + clientes remotos.
///
/// ¿Qué hace?
/// - Lee y escribe metas y registros en SQLite.
/// - Consulta FoodData Central por texto.
/// - Consulta Open Food Facts por código de barras.
///
/// ¿Para qué sirve?
/// Para centralizar en un solo repositorio tanto la parte local
/// como la búsqueda externa.
class DriftNutritionRepository implements NutritionRepository {
  final AppDatabase db;
  final FoodDataCentralApiClient fdcClient;
  final OpenFoodFactsApiClient openFoodFactsClient;

  DriftNutritionRepository(
    this.db, {
    required this.fdcClient,
    required this.openFoodFactsClient,
  });

  @override
  Future<NutritionDayOverview> getDayOverview(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final nextDay = normalizedDate.add(const Duration(days: 1));

    final goal = await _ensureGoal();

    final logRows =
        await (db.select(db.nutritionLogs)
              ..where(
                (table) =>
                    table.loggedAt.isBiggerOrEqualValue(normalizedDate) &
                    table.loggedAt.isSmallerThanValue(nextDay),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.mealType),
                (table) => OrderingTerm.asc(table.loggedAt),
              ]))
            .get();

    final logs = logRows
        .map(
          (row) => NutritionLogEntry(
            id: row.id,
            foodName: row.foodName,
            mealType: MealType.fromStorage(row.mealType),
            sourceType: NutritionSourceType.fromStorage(row.sourceType),
            servingDescription: row.servingDescription,
            externalId: row.externalId,
            calories: row.calories,
            protein: row.protein,
            carbs: row.carbs,
            fats: row.fats,
            loggedAt: row.loggedAt,
          ),
        )
        .toList();

    final summary = DailyNutritionSummary(
      totalCalories: logs.fold(0, (sum, item) => sum + item.calories),
      totalProtein: logs.fold(0, (sum, item) => sum + item.protein),
      totalCarbs: logs.fold(0, (sum, item) => sum + item.carbs),
      totalFats: logs.fold(0, (sum, item) => sum + item.fats),
    );

    return NutritionDayOverview(
      date: normalizedDate,
      goal: goal,
      summary: summary,
      logs: logs,
    );
  }

  @override
  Future<List<NutritionSearchResult>> searchFoods(String query) {
    return fdcClient.searchFoods(query);
  }

  @override
  Future<NutritionSearchResult?> getFoodByBarcode(String barcode) {
    return openFoodFactsClient.getProductByBarcode(barcode);
  }

  @override
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
  }) async {
    final now = DateTime.now();

    await db
        .into(db.nutritionLogs)
        .insert(
          NutritionLogsCompanion.insert(
            id: now.microsecondsSinceEpoch.toString(),
            foodName: foodName.trim(),
            mealType: mealType.name,
            sourceType: Value(sourceType.name),
            servingDescription:
                servingDescription == null || servingDescription.trim().isEmpty
                ? const Value.absent()
                : Value(servingDescription.trim()),
            externalId: externalId == null || externalId.trim().isEmpty
                ? const Value.absent()
                : Value(externalId.trim()),
            calories: Value(calories),
            protein: Value(protein),
            carbs: Value(carbs),
            fats: Value(fats),
            loggedAt: loggedAt,
          ),
        );
  }

  @override
  Future<void> deleteLog(String logId) async {
    await (db.delete(
      db.nutritionLogs,
    )..where((table) => table.id.equals(logId))).go();
  }

  @override
  Future<void> updateGoals({
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    await _ensureGoal();

    await (db.update(
      db.nutritionGoals,
    )..where((table) => table.id.equals(1))).write(
      NutritionGoalsCompanion(
        caloriesGoal: Value(calories),
        proteinGoal: Value(protein),
        carbsGoal: Value(carbs),
        fatsGoal: Value(fats),
      ),
    );
  }

  /// Garantiza que exista una fila de metas.
  ///
  /// ¿Qué hace?
  /// Busca la fila única de metas con `id = 1`.
  /// Si no existe, la crea con valores por defecto.
  ///
  /// ¿Para qué sirve?
  /// Para que el módulo siempre tenga metas disponibles
  /// aunque el usuario nunca las haya configurado.
  Future<domain.NutritionGoal> _ensureGoal() async {
    var row = await (db.select(
      db.nutritionGoals,
    )..where((table) => table.id.equals(1))).getSingleOrNull();

    if (row == null) {
      await db
          .into(db.nutritionGoals)
          .insert(
            NutritionGoalsCompanion.insert(
              id: Value(1),
              caloriesGoal: 2200,
              proteinGoal: 160,
              carbsGoal: 200,
              fatsGoal: 70,
            ),
            mode: InsertMode.insertOrIgnore,
          );

      row = await (db.select(
        db.nutritionGoals,
      )..where((table) => table.id.equals(1))).getSingle();
    }

    return domain.NutritionGoal(
      calories: row.caloriesGoal,
      protein: row.proteinGoal,
      carbs: row.carbsGoal,
      fats: row.fatsGoal,
    );
  }
}
