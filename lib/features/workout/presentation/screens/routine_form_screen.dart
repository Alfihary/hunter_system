import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/muscle_group.dart';
import '../../domain/routine_exercise_input.dart';
import '../providers/workout_controller.dart';

/// Pantalla para crear una rutina.
///
/// ¿Qué hace?
/// Permite capturar:
/// - nombre
/// - descripción
/// - lista dinámica de ejercicios
/// - meta de series por ejercicio
///
/// ¿Para qué sirve?
/// Para crear plantillas reutilizables de entrenamiento.
class RoutineFormScreen extends ConsumerStatefulWidget {
  const RoutineFormScreen({super.key});

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<_ExerciseDraft> _exercises = [_ExerciseDraft()];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    for (final exercise in _exercises) {
      exercise.dispose();
    }

    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseDraft());
    });
  }

  void _removeExercise(int index) {
    if (_exercises.length == 1) return;

    setState(() {
      final removed = _exercises.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final parsedExercises = <RoutineExerciseInput>[];

    for (final exercise in _exercises) {
      final name = exercise.nameController.text.trim();
      final targetSets = int.tryParse(
        exercise.targetSetsController.text.trim(),
      );

      if (name.isEmpty) continue;

      if (targetSets == null || targetSets <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La meta de series del ejercicio "$name" no es válida.',
            ),
          ),
        );
        return;
      }

      parsedExercises.add(
        RoutineExerciseInput(
          name: name,
          muscleGroup: exercise.muscleGroup,
          targetSets: targetSets,
        ),
      );
    }

    if (parsedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ejercicio válido.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await ref
        .read(workoutControllerProvider.notifier)
        .createRoutine(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          exercises: parsedExercises,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva rutina')),
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
                      labelText: 'Nombre de la rutina',
                      hintText: 'Ej. Torso A',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el nombre de la rutina';
                      }
                      if (value.trim().length < 2) {
                        return 'Debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Ej. Rutina base de empuje + pierna',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ejercicios',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _exercises.length,
                    (index) => _ExerciseDraftCard(
                      key: ValueKey('exercise_$index'),
                      draft: _exercises[index],
                      index: index,
                      onRemove: () => _removeExercise(index),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar ejercicio'),
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
                      label: const Text('Guardar rutina'),
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

/// Borrador editable de ejercicio.
class _ExerciseDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController targetSetsController = TextEditingController(
    text: '4',
  );

  MuscleGroup muscleGroup = MuscleGroup.chest;

  void dispose() {
    nameController.dispose();
    targetSetsController.dispose();
  }
}

class _ExerciseDraftCard extends StatefulWidget {
  final _ExerciseDraft draft;
  final int index;
  final VoidCallback onRemove;

  const _ExerciseDraftCard({
    super.key,
    required this.draft,
    required this.index,
    required this.onRemove,
  });

  @override
  State<_ExerciseDraftCard> createState() => _ExerciseDraftCardState();
}

class _ExerciseDraftCardState extends State<_ExerciseDraftCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ejercicio ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.draft.nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del ejercicio',
                hintText: 'Ej. Flexiones inclinadas',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un ejercicio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MuscleGroup>(
              value: widget.draft.muscleGroup,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
              items: MuscleGroup.values.map((group) {
                return DropdownMenuItem(value: group, child: Text(group.label));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  widget.draft.muscleGroup = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.targetSetsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta de series',
                hintText: 'Ej. 4',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa la meta de series';
                }

                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Debe ser un entero mayor que 0';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
