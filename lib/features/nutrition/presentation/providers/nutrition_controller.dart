import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_nutrition_repository.dart';
import '../../data/remote/food_data_central_api_client.dart';
import '../../data/remote/open_food_facts_api_client.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition_day_overview.dart';
import '../../domain/nutrition_repository.dart';
import '../../domain/nutrition_search_result.dart';
import '../../domain/nutrition_source_type.dart';

/// Provider del cliente remoto USDA FoodData Central.
///
/// ¿Qué hace?
/// Lee la API key desde `--dart-define`.
///
/// ¿Para qué sirve?
/// Para evitar hardcodear la API key en el código fuente.
final foodDataCentralApiClientProvider = Provider<FoodDataCentralApiClient>((
  ref,
) {
  const apiKey = String.fromEnvironment('USDA_API_KEY');

  return FoodDataCentralApiClient(apiKey: apiKey);
});

/// Provider del cliente remoto Open Food Facts.
///
/// ¿Qué hace?
/// Expone el cliente usado para consultar productos por barcode.
///
/// ¿Para qué sirve?
/// Para mantener desacoplada la UI de la lógica HTTP.
final openFoodFactsApiClientProvider = Provider<OpenFoodFactsApiClient>((ref) {
  return OpenFoodFactsApiClient();
});

/// Provider del repositorio de nutrición.
///
/// ¿Qué hace?
/// Inyecta la implementación Drift + clientes remotos en la capa de presentación.
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final fdcClient = ref.watch(foodDataCentralApiClientProvider);
  final openFoodFactsClient = ref.watch(openFoodFactsApiClientProvider);

  return DriftNutritionRepository(
    db,
    fdcClient: fdcClient,
    openFoodFactsClient: openFoodFactsClient,
  );
});

/// Controlador de fecha seleccionada en nutrición.
class SelectedNutritionDateController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void goToPreviousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  void goToNextDay() {
    state = state.add(const Duration(days: 1));
  }

  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedNutritionDateProvider =
    NotifierProvider<SelectedNutritionDateController, DateTime>(
      SelectedNutritionDateController.new,
    );

/// Controlador principal del módulo de nutrición.
class NutritionController extends AsyncNotifier<NutritionDayOverview> {
  late final NutritionRepository _repository;

  @override
  Future<NutritionDayOverview> build() async {
    _repository = ref.watch(nutritionRepositoryProvider);
    final date = ref.watch(selectedNutritionDateProvider);
    return _repository.getDayOverview(date);
  }

  Future<String?> createLog({
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
    try {
      final selectedDate = ref.read(selectedNutritionDateProvider);
      final now = DateTime.now();

      final loggedAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      await _repository.createLog(
        loggedAt: loggedAt,
        foodName: foodName,
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
        servingDescription: servingDescription,
        sourceType: sourceType,
        externalId: externalId,
      );

      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> deleteLog(String logId) async {
    try {
      await _repository.deleteLog(logId);
      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> updateGoals({
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      await _repository.updateGoals(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
      );

      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<void> reload() async {
    final date = ref.read(selectedNutritionDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getDayOverview(date));
  }
}

final nutritionControllerProvider =
    AsyncNotifierProvider<NutritionController, NutritionDayOverview>(
      NutritionController.new,
    );

/// Provider de búsqueda remota de alimentos por texto.
final nutritionFoodSearchProvider =
    FutureProvider.family<List<NutritionSearchResult>, String>((
      ref,
      query,
    ) async {
      final cleanedQuery = query.trim();
      if (cleanedQuery.isEmpty) return [];

      final repository = ref.watch(nutritionRepositoryProvider);
      return repository.searchFoods(cleanedQuery);
    });

/// Provider de búsqueda remota por código de barras.
final nutritionBarcodeLookupProvider =
    FutureProvider.family<NutritionSearchResult?, String>((ref, barcode) async {
      final cleanedBarcode = barcode.trim();
      if (cleanedBarcode.isEmpty) return null;

      final repository = ref.watch(nutritionRepositoryProvider);
      return repository.getFoodByBarcode(cleanedBarcode);
    });
