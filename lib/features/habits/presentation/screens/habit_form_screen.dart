import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/habit_category.dart';
import '../../domain/habit_summary.dart';
import '../providers/habits_controller.dart';

/// Pantalla de formulario de hábito.
///
/// ¿Qué hace?
/// Sirve tanto para crear como para editar un hábito.
///
/// ¿Para qué sirve?
/// Reutilizar una sola pantalla para dos casos de uso:
/// - alta
/// - edición
class HabitFormScreen extends ConsumerStatefulWidget {
  final HabitSummary? initialHabit;

  const HabitFormScreen({super.key, this.initialHabit});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _xpController;

  late HabitCategory _selectedCategory;
  bool _isSaving = false;

  bool get _isEditing => widget.initialHabit != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialHabit?.name ?? '',
    );

    _xpController = TextEditingController(
      text: (widget.initialHabit?.xpReward ?? 10).toString(),
    );

    _selectedCategory = widget.initialHabit?.category ?? HabitCategory.physical;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final xpReward = int.parse(_xpController.text);

    String? error;

    if (_isEditing) {
      error = await ref
          .read(habitsControllerProvider.notifier)
          .updateHabit(
            id: widget.initialHabit!.id,
            name: name,
            category: _selectedCategory,
            xpReward: xpReward,
          );
    } else {
      error = await ref
          .read(habitsControllerProvider.notifier)
          .createHabit(
            name: name,
            category: _selectedCategory,
            xpReward: xpReward,
          );
    }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar hábito' : 'Nuevo hábito'),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del hábito',
                      hintText: 'Ej. Tomar 2L de agua',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      if (value.trim().length < 2) {
                        return 'Debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<HabitCategory>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: HabitCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _xpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'XP recompensa',
                      hintText: 'Ej. 10',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un valor de XP';
                      }

                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return 'Debe ser un número entero';
                      }
                      if (parsed < 1 || parsed > 1000) {
                        return 'Usa un valor entre 1 y 1000';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
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
                      label: Text(
                        _isEditing ? 'Guardar cambios' : 'Crear hábito',
                      ),
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
