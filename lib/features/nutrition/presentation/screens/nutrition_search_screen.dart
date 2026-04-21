import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/nutrition_search_result.dart';
import '../providers/nutrition_controller.dart';

/// Pantalla de búsqueda remota de alimentos.
///
/// ¿Qué hace?
/// Permite escribir un texto, consultar USDA FoodData Central
/// y mostrar resultados seleccionables.
///
/// ¿Para qué sirve?
/// Para reducir captura manual y acelerar el registro de alimentos.
class NutritionSearchScreen extends ConsumerStatefulWidget {
  const NutritionSearchScreen({super.key});

  @override
  ConsumerState<NutritionSearchScreen> createState() =>
      _NutritionSearchScreenState();
}

class _NutritionSearchScreenState extends ConsumerState<NutritionSearchScreen> {
  final TextEditingController _queryController = TextEditingController();

  String _submittedQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    setState(() {
      _submittedQuery = _queryController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(
      nutritionFoodSearchProvider(_submittedQuery),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar alimento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Buscar alimento',
                      hintText: 'Ej. chicken breast, rice, banana',
                    ),
                    onSubmitted: (_) => _submitSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _submitSearch,
                  child: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _submittedQuery.isEmpty
                  ? const Center(
                      child: Text(
                        'Escribe un alimento para buscar en FoodData Central.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return const Center(
                            child: Text(
                              'No se encontraron resultados.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final result = results[index];

                            return _SearchResultCard(result: result);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final NutritionSearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(result.foodName),
        subtitle: Text(result.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/nutrition/log', extra: result);
        },
      ),
    );
  }
}
