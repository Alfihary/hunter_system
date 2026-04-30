import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/meal_type.dart';
import '../../domain/nutrition_search_result.dart';
import '../../domain/nutrition_source_type.dart';
import '../providers/nutrition_controller.dart';

/// Pantalla para registrar un alimento manualmente o desde un resultado API.
///
/// ¿Qué hace?
/// Permite capturar:
/// - nombre del alimento
/// - tipo de comida
/// - porción
/// - calorías
/// - proteína
/// - carbohidratos
/// - grasas
///
/// ¿Para qué sirve?
/// Es la base del módulo de nutrición.
/// Si llega un resultado de búsqueda o barcode, prellena los datos.
class NutritionLogFormScreen extends ConsumerStatefulWidget {
  final NutritionSearchResult? initialSearchResult;

  const NutritionLogFormScreen({super.key, this.initialSearchResult});

  @override
  ConsumerState<NutritionLogFormScreen> createState() =>
      _NutritionLogFormScreenState();
}

class _NutritionLogFormScreenState
    extends ConsumerState<NutritionLogFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _foodNameController;
  late final TextEditingController _servingController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatsController;

  MealType _selectedMealType = MealType.breakfast;
  bool _isSaving = false;

  bool get _isFromApi => widget.initialSearchResult != null;

  @override
  void initState() {
    super.initState();

    final result = widget.initialSearchResult;

    _foodNameController = TextEditingController(text: result?.foodName ?? '');
    _servingController = TextEditingController(
      text: result?.servingDescription ?? '',
    );
    _caloriesController = TextEditingController(
      text: result == null ? '' : result.calories.toStringAsFixed(0),
    );
    _proteinController = TextEditingController(
      text: result == null ? '' : result.protein.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: result == null ? '' : result.carbs.toStringAsFixed(1),
    );
    _fatsController = TextEditingController(
      text: result == null ? '' : result.fats.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _servingController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final calories = double.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fats = double.tryParse(_fatsController.text.trim());

    if (calories == null || protein == null || carbs == null || fats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores nutricionales inválidos.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await ref
        .read(nutritionControllerProvider.notifier)
        .createLog(
          foodName: _foodNameController.text.trim(),
          mealType: _selectedMealType,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          servingDescription: _servingController.text.trim(),
          sourceType:
              widget.initialSearchResult?.sourceType ??
              NutritionSourceType.manual,
          externalId: widget.initialSearchResult?.externalId,
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedNutritionDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFromApi ? 'Confirmar alimento' : 'Agregar alimento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Se registrará en: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  if (_isFromApi) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Fuente: ${widget.initialSearchResult!.sourceType.label}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del alimento',
                      hintText: 'Ej. Pechuga de pollo',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el nombre del alimento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MealType>(
                    initialValue: _selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de comida',
                    ),
                    items: MealType.values.map((mealType) {
                      return DropdownMenuItem(
                        value: mealType,
                        child: Text(mealType.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedMealType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _servingController,
                    decoration: const InputDecoration(
                      labelText: 'Porción (opcional)',
                      hintText: 'Ej. 150 g / 1 pieza',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Calorías'),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 0) {
                        return 'Ingresa calorías válidas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Proteína'),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 0) {
                        return 'Ingresa proteína válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Carbohidratos',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 0) {
                        return 'Ingresa carbohidratos válidos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fatsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Grasas'),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 0) {
                        return 'Ingresa grasas válidas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar alimento'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
