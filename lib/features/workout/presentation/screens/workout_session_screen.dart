import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/routine_exercise_input.dart';
import '../../domain/workout_block.dart';
import '../../domain/workout_set_entry.dart';
import '../../domain/workout_set_type.dart';
import '../providers/workout_controller.dart';

/// Pantalla de sesión de entrenamiento estilo rápido.
///
/// ¿Qué hace?
/// - muestra un panel global de descanso arriba
/// - agrupa ejercicios en tabs por bloque
/// - permite capturar sets inline sin abrir diálogos
/// - muestra cuántas series llevas por ejercicio
/// - muestra el historial de sets dentro de cada card
///
/// ¿Para qué sirve?
/// Para que registrar una sesión sea rápido, fluido y cómodo,
/// muy parecido al flujo de una app de entrenamiento real.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String routineId;

  const WorkoutSessionScreen({
    super.key,
    required this.routineId,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  String? _workoutId;
  bool _isStarting = false;
  bool _isFinishing = false;

  /// Bloque seleccionado actualmente en las tabs.
  WorkoutBlock? _selectedBlock;

  /// Timer global de descanso.
  Timer? _restTimer;

  /// Segundos restantes del descanso actual.
  int _restSecondsRemaining = 0;

  /// Duración total del descanso actual.
  int _restTotalSeconds = 60;

  /// Preset seleccionado actualmente.
  int _selectedRestPreset = 60;

  bool get _isRestRunning =>
      _restTimer != null &&
      _restTimer!.isActive &&
      _restSecondsRemaining > 0;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  /// Inicia la sesión real en base de datos.
  Future<void> _startWorkout() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final workoutId = await ref
          .read(workoutControllerProvider.notifier)
          .startWorkout(widget.routineId);

      if (!mounted) return;

      setState(() {
        _workoutId = workoutId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión iniciada.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  /// Finaliza la sesión actual.
  Future<void> _finishWorkout() async {
    if (_workoutId == null) return;

    setState(() {
      _isFinishing = true;
    });

    final error = await ref
        .read(workoutControllerProvider.notifier)
        .finishWorkout(_workoutId!);

    if (!mounted) return;

    setState(() {
      _isFinishing = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _restTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión finalizada.')),
    );

    Navigator.of(context).pop();
  }

  /// Inicia o reinicia el descanso global.
  ///
  /// ¿Qué hace?
  /// Arranca una cuenta regresiva visible para todos los ejercicios.
  ///
  /// ¿Para qué sirve?
  /// Para que el descanso no dependa de una card específica.
  void _startRestTimer(int seconds) {
    _restTimer?.cancel();

    setState(() {
      _selectedRestPreset = seconds;
      _restTotalSeconds = seconds;
      _restSecondsRemaining = seconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _restSecondsRemaining = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descanso terminado.')),
        );
        return;
      }

      setState(() {
        _restSecondsRemaining--;
      });
    });
  }

  /// Pausa o reanuda el descanso actual.
  void _togglePauseResumeTimer() {
    if (_restSecondsRemaining <= 0) return;

    if (_isRestRunning) {
      _restTimer?.cancel();
      setState(() {});
      return;
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _restSecondsRemaining = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descanso terminado.')),
        );
        return;
      }

      setState(() {
        _restSecondsRemaining--;
      });
    });

    setState(() {});
  }

  /// Reinicia el descanso y lo deja en cero.
  void _resetRestTimer() {
    _restTimer?.cancel();

    setState(() {
      _restSecondsRemaining = 0;
    });
  }

  /// Guarda un set directamente desde una card.
  ///
  /// ¿Qué hace?
  /// Envía el set al controlador y, si sale bien,
  /// arranca automáticamente el descanso global.
  Future<String?> _saveInlineSet({
    required RoutineExerciseInput exercise,
    required WorkoutSetType setType,
    required int? reps,
    required int? durationSeconds,
    required double? weight,
  }) async {
    if (_workoutId == null) {
      return 'Primero debes iniciar la sesión.';
    }

    final error = await ref.read(workoutControllerProvider.notifier).addWorkoutSet(
          workoutId: _workoutId!,
          exerciseName: exercise.name,
          muscleGroup: exercise.muscleGroup.name,
          setType: setType,
          reps: reps,
          durationSeconds: durationSeconds,
          weight: weight,
        );

    if (error == null) {
      _startRestTimer(_selectedRestPreset);
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(workoutRoutineDetailProvider(widget.routineId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión de entrenamiento'),
      ),
      body: routineAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (routine) {
          if (routine == null) {
            return const Center(
              child: Text('No se encontró la rutina.'),
            );
          }

          final allSetsAsync = _workoutId == null
              ? const AsyncData<List<WorkoutSetEntry>>(<WorkoutSetEntry>[])
              : ref.watch(workoutSetEntriesProvider(_workoutId!));

  final allSets = allSetsAsync.when(
  data: (data) => data,
  loading: () => const <WorkoutSetEntry>[],
  error: (_, __) => const <WorkoutSetEntry>[],
);

          final availableBlocks = routine.exercises
              .map((exercise) => WorkoutBlock.fromMuscleGroup(exercise.muscleGroup))
              .toSet()
              .toList()
            ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

          final currentBlock = _selectedBlock != null &&
                  availableBlocks.contains(_selectedBlock)
              ? _selectedBlock!
              : availableBlocks.first;

          final visibleExercises = routine.exercises.where((exercise) {
            return WorkoutBlock.fromMuscleGroup(exercise.muscleGroup) ==
                currentBlock;
          }).toList();

          return Column(
            children: [
              _SessionHeader(
                dateText: _formatDateHeader(DateTime.now()),
                totalSets: allSets.length,
              ),
              _RestTimerPanel(
                remainingSeconds: _restSecondsRemaining,
                totalSeconds: _restTotalSeconds,
                selectedPreset: _selectedRestPreset,
                isRunning: _isRestRunning,
                onSelectPreset: _startRestTimer,
                onPauseResume: _togglePauseResumeTimer,
                onReset: _resetRestTimer,
              ),
              _WorkoutBlockTabs(
                blocks: availableBlocks,
                selectedBlock: currentBlock,
                onSelected: (block) {
                  setState(() {
                    _selectedBlock = block;
                  });
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              routine.name,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (routine.description != null &&
                                routine.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                routine.description!,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text('Ejercicios visibles: ${visibleExercises.length}'),
                            const SizedBox(height: 6),
                            Text('Sets totales guardados: ${allSets.length}'),
                            const SizedBox(height: 16),
                            if (_workoutId == null)
                              FilledButton.icon(
                                onPressed: _isStarting ? null : _startWorkout,
                                icon: _isStarting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Comenzar sesión'),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _isFinishing ? null : _finishWorkout,
                                icon: _isFinishing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.stop),
                                label: const Text('Finalizar sesión'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...visibleExercises.map((exercise) {
                      final exerciseSets = allSets
                          .where((set) => set.exerciseName == exercise.name)
                          .toList();

                      return _ExerciseSessionCard(
                        key: ValueKey(exercise.name),
                        exercise: exercise,
                        sets: exerciseSets,
                        enabled: _workoutId != null,
                        onSaveSet: ({
                          required WorkoutSetType setType,
                          required int? reps,
                          required int? durationSeconds,
                          required double? weight,
                        }) {
                          return _saveInlineSet(
                            exercise: exercise,
                            setType: setType,
                            reps: reps,
                            durationSeconds: durationSeconds,
                            weight: weight,
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Formatea la fecha superior de la sesión.
  String _formatDateHeader(DateTime date) {
    const weekdays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    final weekday = weekdays[date.weekday - 1];
    return '$weekday ${date.day}/${date.month}/${date.year}';
  }
}

/// Encabezado visual de la sesión.
///
/// ¿Qué hace?
/// Muestra la fecha y una cápsula compacta de progreso.
class _SessionHeader extends StatelessWidget {
  final String dateText;
  final int totalSets;

  const _SessionHeader({
    required this.dateText,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESIÓN DE ENTRENAMIENTO',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Text(
              '$totalSets sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel global de descanso.
///
/// ¿Qué hace?
/// Muestra el estado del descanso actual para toda la sesión.
///
/// ¿Para qué sirve?
/// Para que el usuario siempre tenga visible cuánto le falta descansar.
class _RestTimerPanel extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final int selectedPreset;
  final bool isRunning;
  final ValueChanged<int> onSelectPreset;
  final VoidCallback onPauseResume;
  final VoidCallback onReset;

  const _RestTimerPanel({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.selectedPreset,
    required this.isRunning,
    required this.onSelectPreset,
    required this.onPauseResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    final statusText = remainingSeconds <= 0
        ? 'Listo'
        : isRunning
            ? _formatSeconds(remainingSeconds)
            : 'Pausado • ${_formatSeconds(remainingSeconds)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESCANSO ENTRE SERIES',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: remainingSeconds <= 0 ? 0 : progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PresetButton(
                    label: '1 min',
                    isSelected: selectedPreset == 60,
                    onPressed: () => onSelectPreset(60),
                  ),
                  _PresetButton(
                    label: '2 min',
                    isSelected: selectedPreset == 120,
                    onPressed: () => onSelectPreset(120),
                  ),
                  _PresetButton(
                    label: '3 min',
                    isSelected: selectedPreset == 180,
                    onPressed: () => onSelectPreset(180),
                  ),
                  OutlinedButton(
                    onPressed: onPauseResume,
                    child: Text(isRunning ? 'Pausar' : 'Reanudar'),
                  ),
                  OutlinedButton(
                    onPressed: onReset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Botón visual de preset de descanso.
class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Tabs horizontales por bloque de entrenamiento.
///
/// ¿Qué hace?
/// Filtra visualmente los ejercicios de la sesión.
class _WorkoutBlockTabs extends StatelessWidget {
  final List<WorkoutBlock> blocks;
  final WorkoutBlock selectedBlock;
  final ValueChanged<WorkoutBlock> onSelected;

  const _WorkoutBlockTabs({
    required this.blocks,
    required this.selectedBlock,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: blocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final block = blocks[index];
          final isSelected = block == selectedBlock;

          return ChoiceChip(
            label: Text(block.label),
            selected: isSelected,
            onSelected: (_) => onSelected(block),
          );
        },
      ),
    );
  }
}

/// Card de ejercicio con captura rápida de sets.
///
/// ¿Qué hace?
/// Muestra:
/// - nombre del ejercicio
/// - contador de series
/// - historial inline
/// - input rápido de reps/segundos
/// - toggle de dropset/isométrico
///
/// ¿Para qué sirve?
/// Para registrar sets sin abrir ventanas adicionales.
class _ExerciseSessionCard extends ConsumerStatefulWidget {
  final RoutineExerciseInput exercise;
  final List<WorkoutSetEntry> sets;
  final bool enabled;
  final Future<String?> Function({
    required WorkoutSetType setType,
    required int? reps,
    required int? durationSeconds,
    required double? weight,
  }) onSaveSet;

  const _ExerciseSessionCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.enabled,
    required this.onSaveSet,
  });

  @override
  ConsumerState<_ExerciseSessionCard> createState() =>
      _ExerciseSessionCardState();
}

class _ExerciseSessionCardState extends ConsumerState<_ExerciseSessionCard> {
  final TextEditingController _valueController =
      TextEditingController(text: '10');

  final TextEditingController _weightController = TextEditingController();

  WorkoutSetType _selectedType = WorkoutSetType.normal;
  bool _isSaving = false;

  @override
  void dispose() {
    _valueController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Alterna entre normal y dropset.
  void _toggleDropSet() {
    setState(() {
      _selectedType = _selectedType == WorkoutSetType.dropSet
          ? WorkoutSetType.normal
          : WorkoutSetType.dropSet;
    });
  }

  /// Alterna entre normal e isométrico.
  void _toggleIsometric() {
    setState(() {
      _selectedType = _selectedType == WorkoutSetType.isometric
          ? WorkoutSetType.normal
          : WorkoutSetType.isometric;
    });
  }

  Future<void> _submit() async {
    if (!widget.enabled) return;

    final rawValue = _valueController.text.trim();
    final rawWeight = _weightController.text.trim();

    final weight = rawWeight.isEmpty ? null : double.tryParse(rawWeight);

    if (rawWeight.isNotEmpty && weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso inválido.')),
      );
      return;
    }

    int? reps;
    int? durationSeconds;

    if (_selectedType == WorkoutSetType.isometric) {
      durationSeconds = int.tryParse(rawValue);

      if (durationSeconds == null || durationSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa segundos válidos.')),
        );
        return;
      }
    } else {
      reps = int.tryParse(rawValue);

      if (reps == null || reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa repeticiones válidas.')),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final error = await widget.onSaveSet(
      setType: _selectedType,
      reps: reps,
      durationSeconds: durationSeconds,
      weight: weight,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    /// Después de guardar, regresamos a tipo normal
    /// para evitar errores por olvidarse un toggle activo.
    setState(() {
      _selectedType = WorkoutSetType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seriesCount = widget.sets.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Encabezado del ejercicio
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(
                    '$seriesCount serie${seriesCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Historial inline del ejercicio
            if (widget.sets.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Aún no tienes sets guardados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: List.generate(widget.sets.length, (index) {
                    final set = widget.sets[index];
                    return _SavedSetRow(
                      seriesIndex: index + 1,
                      set: set,
                    );
                  }),
                ),
              ),

            const Divider(height: 20),

            /// Captura rápida
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valueController,
                    enabled: widget.enabled && !_isSaving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _selectedType == WorkoutSetType.isometric
                          ? 'segundos'
                          : 'reps',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: OutlinedButton(
                    onPressed:
                        widget.enabled && !_isSaving ? _toggleDropSet : null,
                    child: Text(
                      'DROP',
                      style: TextStyle(
                        fontWeight: _selectedType == WorkoutSetType.dropSet
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 78,
                  child: OutlinedButton(
                    onPressed:
                        widget.enabled && !_isSaving ? _toggleIsometric : null,
                    child: Text(
                      'ISO',
                      style: TextStyle(
                        fontWeight: _selectedType == WorkoutSetType.isometric
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: FilledButton(
                    onPressed: widget.enabled && !_isSaving ? _submit : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('+ SERIE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Peso opcional
            TextField(
              controller: _weightController,
              enabled: widget.enabled && !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso opcional',
                hintText: 'Ej. 12.5',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila visual de set ya guardado.
///
/// ¿Qué hace?
/// Resume cada set en una línea compacta dentro de la card del ejercicio.
class _SavedSetRow extends StatelessWidget {
  final int seriesIndex;
  final WorkoutSetEntry set;

  const _SavedSetRow({
    required this.seriesIndex,
    required this.set,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Serie $seriesIndex'),
          ),
          Expanded(
            flex: 3,
            child: Text(_buildSetText()),
          ),
          if (set.setType == WorkoutSetType.dropSet)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const Text('DROPSET'),
            ),
          if (set.setType == WorkoutSetType.isometric)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
              child: const Text('ISO'),
            ),
          Text(
            _formatTime(set.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _buildSetText() {
    switch (set.setType) {
      case WorkoutSetType.normal:
        return set.weight == null
            ? '${set.reps} reps'
            : '${set.reps} reps • ${set.weight} kg';
      case WorkoutSetType.dropSet:
        return set.weight == null
            ? '${set.reps} reps'
            : '${set.reps} reps • ${set.weight} kg';
      case WorkoutSetType.isometric:
        return set.weight == null
            ? '${set.durationSeconds}s'
            : '${set.durationSeconds}s • ${set.weight} kg';
    }
  }

  String _formatTime(DateTime date) {
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $suffix';
  }
}