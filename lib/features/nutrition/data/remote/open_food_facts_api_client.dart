import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/nutrition_search_result.dart';
import '../../domain/nutrition_source_type.dart';

/// Cliente remoto para Open Food Facts.
///
/// ¿Qué hace?
/// Consulta un producto por código de barras.
///
/// ¿Para qué sirve?
/// Para que el usuario pueda escanear un producto real y obtener,
/// si existe, sus datos nutricionales básicos para registrarlo.
class OpenFoodFactsApiClient {
  final http.Client _httpClient;

  OpenFoodFactsApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Busca un producto por código de barras.
  ///
  /// ¿Qué hace?
  /// Llama a Open Food Facts usando el barcode escaneado.
  ///
  /// ¿Qué devuelve?
  /// - Un [NutritionSearchResult] si el producto fue encontrado.
  /// - `null` si no existe en la base abierta.
  Future<NutritionSearchResult?> getProductByBarcode(String barcode) async {
    final cleanedBarcode = barcode.trim();

    if (cleanedBarcode.isEmpty) return null;

    final uri = Uri.https(
      'world.openfoodfacts.net',
      '/api/v2/product/$cleanedBarcode',
      {'fields': 'product_name,brands,serving_size,nutriments,code'},
    );

    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar Open Food Facts. Código: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'];

    if (status != 1) {
      return null;
    }

    final product = decoded['product'] as Map<String, dynamic>? ?? {};
    final nutriments =
        product['nutriments'] as Map<String, dynamic>? ?? const {};

    final foodName =
        _readAsString(product['product_name'])?.trim().isNotEmpty == true
        ? _readAsString(product['product_name'])!.trim()
        : 'Producto sin nombre';

    final brandName = _readAsString(product['brands']);
    final servingDescription = _readAsString(product['serving_size']);

    return NutritionSearchResult(
      externalId: _readAsString(decoded['code']) ?? cleanedBarcode,
      foodName: foodName,
      brandName: brandName,
      servingDescription: servingDescription,
      calories:
          _readAsDouble(nutriments['energy-kcal_100g']) ??
          _readAsDouble(nutriments['energy-kcal']) ??
          0,
      protein:
          _readAsDouble(nutriments['proteins_100g']) ??
          _readAsDouble(nutriments['proteins']) ??
          0,
      carbs:
          _readAsDouble(nutriments['carbohydrates_100g']) ??
          _readAsDouble(nutriments['carbohydrates']) ??
          0,
      fats:
          _readAsDouble(nutriments['fat_100g']) ??
          _readAsDouble(nutriments['fat']) ??
          0,
      sourceType: NutritionSourceType.openFoodFacts,
    );
  }

  /// Convierte cualquier valor compatible a String.
  String? _readAsString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Convierte cualquier valor compatible a double.
  double? _readAsDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
