import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/nutrition_search_result.dart';
import '../../domain/nutrition_source_type.dart';

/// Cliente remoto para USDA FoodData Central.
///
/// ¿Qué hace?
/// Consulta la API oficial de FoodData Central para buscar alimentos.
///
/// ¿Para qué sirve?
/// Para traer resultados remotos que luego se puedan registrar
/// en la base local como snapshot.
///
/// Importante:
/// - No guarda nada en la base de datos.
/// - Sólo busca y transforma la respuesta HTTP.
class FoodDataCentralApiClient {
  final String apiKey;
  final http.Client _httpClient;

  FoodDataCentralApiClient({required this.apiKey, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Busca alimentos por texto.
  ///
  /// ¿Qué hace?
  /// Llama al endpoint `/foods/search` de USDA.
  ///
  /// ¿Para qué sirve?
  /// Para obtener resultados que luego el usuario podrá seleccionar
  /// y registrar en su diario nutricional.
  Future<List<NutritionSearchResult>> searchFoods(
    String query, {
    int pageSize = 20,
  }) async {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) return [];

    if (apiKey.trim().isEmpty) {
      throw Exception(
        'No se encontró USDA_API_KEY. Ejecuta la app con --dart-define=USDA_API_KEY=TU_API_KEY',
      );
    }

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': apiKey,
      'query': cleanedQuery,
      'pageSize': '$pageSize',
    });

    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar FoodData Central. Código: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = (decoded['foods'] as List<dynamic>? ?? const []);

    return foods.map((item) {
      final map = item as Map<String, dynamic>;
      final nutrients = (map['foodNutrients'] as List<dynamic>? ?? const []);

      final servingSize = _readAsDouble(map['servingSize']);
      final servingUnit = _readAsString(map['servingSizeUnit']);

      final servingDescription =
          servingSize != null && servingUnit != null && servingUnit.isNotEmpty
          ? '${servingSize.toStringAsFixed(servingSize.truncateToDouble() == servingSize ? 0 : 1)} $servingUnit'
          : null;

      return NutritionSearchResult(
        externalId: _readAsString(map['fdcId']) ?? '',
        foodName: _readAsString(map['description']) ?? 'Sin nombre',
        brandName: _readAsString(map['brandOwner']),
        servingDescription: servingDescription,
        calories: _extractCalories(nutrients),
        protein: _extractProtein(nutrients),
        carbs: _extractCarbs(nutrients),
        fats: _extractFats(nutrients),
        sourceType: NutritionSourceType.fdc,
      );
    }).toList();
  }

  /// Extrae calorías desde la lista de nutrientes.
  ///
  /// La respuesta de FDC puede variar según el tipo de alimento,
  /// así que usamos búsqueda flexible por nombre y unidad.
  double _extractCalories(List<dynamic> nutrients) {
    for (final raw in nutrients) {
      final item = raw as Map<String, dynamic>;
      final name =
          (_readAsString(item['nutrientName']) ??
                  _readAsString(item['name']) ??
                  '')
              .toLowerCase();

      final unit = (_readAsString(item['unitName']) ?? '').toLowerCase();

      if (name.contains('energy') && (unit == 'kcal' || unit.isEmpty)) {
        return _readAsDouble(item['value']) ??
            _readAsDouble(item['amount']) ??
            0;
      }
    }

    return 0;
  }

  /// Extrae proteína.
  double _extractProtein(List<dynamic> nutrients) {
    return _extractByNames(nutrients, matches: const ['protein']);
  }

  /// Extrae carbohidratos.
  double _extractCarbs(List<dynamic> nutrients) {
    return _extractByNames(
      nutrients,
      matches: const ['carbohydrate', 'carbohydrates'],
    );
  }

  /// Extrae grasas.
  double _extractFats(List<dynamic> nutrients) {
    return _extractByNames(
      nutrients,
      matches: const ['total lipid', 'fat', 'fats'],
    );
  }

  /// Busca un nutriente por coincidencia flexible de nombre.
  double _extractByNames(
    List<dynamic> nutrients, {
    required List<String> matches,
  }) {
    for (final raw in nutrients) {
      final item = raw as Map<String, dynamic>;
      final name =
          (_readAsString(item['nutrientName']) ??
                  _readAsString(item['name']) ??
                  '')
              .toLowerCase();

      final matched = matches.any((token) => name.contains(token));
      if (!matched) continue;

      return _readAsDouble(item['value']) ?? _readAsDouble(item['amount']) ?? 0;
    }

    return 0;
  }

  /// Lee un valor como `String`.
  String? _readAsString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Lee un valor como `double`.
  double? _readAsDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
