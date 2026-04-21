import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exercise_last_session_summary.dart';
import '../../domain/routine_exercise_input.dart';
import '../../domain/workout_block.dart';
import '../../domain/workout_set_entry.dart';
import '../../domain/workout_set_type.dart';
import '../providers/workout_controller.dart';

/// Pantalla de sesión de entrenamiento.
///
/// ¿Qué hace?
/// - muestra la rutina actual
/// - permite iniciar/finalizar sesión
/// - registra series inline
/// - muestra contador actual/meta
/// - muestra comparación contra la última sesión
/// - controla un descanso global
///
/// ¿Para qué sirve?
/// Para que el usuario registre su entrenamiento con contexto real:
/// no sólo qué hace hoy, sino también contra qué está comparando.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String routineId;

  const WorkoutSessionScreen({super.key, required this.routineId});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  String? _workoutId;
  bool _isStarting = false;
  bool _isFinishing = false;

  WorkoutBlock? _selectedBlock;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 60;
  int _selectedRestPreset = 60;

  bool get _isRestRunning =>
      _restTimer != null && _restTimer!.isActive && _restSecondsRemaining > 0;

  bool get _sessionStarted => _workoutId != null;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión iniciada.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _restTimer?.cancel();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sesión finalizada.')));

    Navigator.of(context).pop();
  }

  /// Inicia el cronómetro global de descanso.
  void _startRestTimer(int seconds) {
    _restTimer?.cancel();

    setState(() {
      _selectedRestPreset = seconds;
      _restTotalSeconds = seconds;
      _restSecondsRemaining = seconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _restSecondsRemaining = 0;
        });

        await HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Descanso terminado.')));
        return;
      }

      setState(() {
        _restSecondsRemaining--;
      });
    });
  }

  void _togglePauseResumeTimer() {
    if (_restSecondsRemaining <= 0) return;

    if (_isRestRunning) {
      _restTimer?.cancel();
      setState(() {});
      return;
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _restSecondsRemaining = 0;
        });

        await HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Descanso terminado.')));
        return;
      }

      setState(() {
        _restSecondsRemaining--;
      });
    });

    setState(() {});
  }

  void _resetRestTimer() {
    _restTimer?.cancel();

    setState(() {
      _restSecondsRemaining = 0;
    });
  }

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

    final error = await ref
        .read(workoutControllerProvider.notifier)
        .addWorkoutSet(
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
    final routineAsync = ref.watch(
      workoutRoutineDetailProvider(widget.routineId),
    );
    final comparisonAsync = ref.watch(
      lastRoutineSessionComparisonProvider(widget.routineId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Sesión')),
      body: routineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (routine) {
          if (routine == null) {
            return const Center(child: Text('No se encontró la rutina.'));
          }

          final allSetsAsync = _workoutId == null
              ? const AsyncData<List<WorkoutSetEntry>>(<WorkoutSetEntry>[])
              : ref.watch(workoutSetEntriesProvider(_workoutId!));

          final allSets = allSetsAsync.when(
            data: (value) => value,
            loading: () => const <WorkoutSetEntry>[],
            error: (_, __) => const <WorkoutSetEntry>[],
          );

          final comparisonMap = comparisonAsync.when(
            data: (value) => value,
            loading: () => const <String, ExerciseLastSessionSummary>{},
            error: (_, __) => const <String, ExerciseLastSessionSummary>{},
          );

          final availableBlocks =
              routine.exercises
                  .map(
                    (exercise) =>
                        WorkoutBlock.fromMuscleGroup(exercise.muscleGroup),
                  )
                  .toSet()
                  .toList()
                ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

          if (availableBlocks.isEmpty) {
            return const Center(
              child: Text('Esta rutina no tiene ejercicios.'),
            );
          }

          final currentBlock =
              _selectedBlock != null && availableBlocks.contains(_selectedBlock)
              ? _selectedBlock!
              : availableBlocks.first;

          final visibleExercises = routine.exercises.where((exercise) {
            return WorkoutBlock.fromMuscleGroup(exercise.muscleGroup) ==
                currentBlock;
          }).toList();

          return Column(
            children: [
              _CompactTopPanel(
                routineName: routine.name,
                totalSets: allSets.length,
                sessionStarted: _sessionStarted,
                isStarting: _isStarting,
                isFinishing: _isFinishing,
                remainingSeconds: _restSecondsRemaining,
                totalSeconds: _restTotalSeconds,
                selectedPreset: _selectedRestPreset,
                isRestRunning: _isRestRunning,
                onSelectPreset: _startRestTimer,
                onPauseResume: _togglePauseResumeTimer,
                onReset: _resetRestTimer,
                onStart: _startWorkout,
                onFinish: _finishWorkout,
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
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    ...visibleExercises.map((exercise) {
                      final exerciseSets = allSets
                          .where((set) => set.exerciseName == exercise.name)
                          .toList();

                      final previousSummary = comparisonMap[exercise.name];

                      return _ExerciseSessionCard(
                        key: ValueKey(exercise.name),
                        exercise: exercise,
                        sets: exerciseSets,
                        previousSummary: previousSummary,
                        enabled: _sessionStarted,
                        onSaveSet:
                            ({
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
}

/// Panel superior compacto.
class _CompactTopPanel extends StatelessWidget {
  final String routineName;
  final int totalSets;
  final bool sessionStarted;
  final bool isStarting;
  final bool isFinishing;
  final int remainingSeconds;
  final int totalSeconds;
  final int selectedPreset;
  final bool isRestRunning;
  final ValueChanged<int> onSelectPreset;
  final VoidCallback onPauseResume;
  final VoidCallback onReset;
  final Future<void> Function() onStart;
  final Future<void> Function() onFinish;

  const _CompactTopPanel({
    required this.routineName,
    required this.totalSets,
    required this.sessionStarted,
    required this.isStarting,
    required this.isFinishing,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.selectedPreset,
    required this.isRestRunning,
    required this.onSelectPreset,
    required this.onPauseResume,
    required this.onReset,
    required this.onStart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    final timerText = remainingSeconds <= 0
        ? 'Listo'
        : _formatSeconds(remainingSeconds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routineName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Text(
                      '$totalSets sets',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: remainingSeconds <= 0 ? 0 : progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    timerText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniPresetButton(
                    label: '1m',
                    selected: selectedPreset == 60,
                    onPressed: () => onSelectPreset(60),
                  ),
                  _MiniPresetButton(
                    label: '2m',
                    selected: selectedPreset == 120,
                    onPressed: () => onSelectPreset(120),
                  ),
                  _MiniPresetButton(
                    label: '3m',
                    selected: selectedPreset == 180,
                    onPressed: () => onSelectPreset(180),
                  ),
                  OutlinedButton(
                    onPressed: onPauseResume,
                    child: Text(isRestRunning ? 'Pausar' : 'Reanudar'),
                  ),
                  OutlinedButton(
                    onPressed: onReset,
                    child: const Text('Reset'),
                  ),
                  sessionStarted
                      ? FilledButton(
                          onPressed: isFinishing ? null : onFinish,
                          child: isFinishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Finalizar'),
                        )
                      : FilledButton(
                          onPressed: isStarting ? null : onStart,
                          child: isStarting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Comenzar'),
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

class _MiniPresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _MiniPresetButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
      ),
      child: Text(label),
    );
  }
}

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
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: blocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final block = blocks[index];

          return ChoiceChip(
            label: Text(block.label),
            selected: block == selectedBlock,
            onSelected: (_) => onSelected(block),
          );
        },
      ),
    );
  }
}

/// Card de ejercicio con:
/// - progreso actual/meta
/// - historial del día
/// - comparación contra la última sesión
class _ExerciseSessionCard extends ConsumerStatefulWidget {
  final RoutineExerciseInput exercise;
  final List<WorkoutSetEntry> sets;
  final ExerciseLastSessionSummary? previousSummary;
  final bool enabled;
  final Future<String?> Function({
    required WorkoutSetType setType,
    required int? reps,
    required int? durationSeconds,
    required double? weight,
  })
  onSaveSet;

  const _ExerciseSessionCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.previousSummary,
    required this.enabled,
    required this.onSaveSet,
  });

  @override
  ConsumerState<_ExerciseSessionCard> createState() =>
      _ExerciseSessionCardState();
}

class _ExerciseSessionCardState extends ConsumerState<_ExerciseSessionCard> {
  final TextEditingController _mainValueController = TextEditingController(
    text: '10',
  );

  final TextEditingController _weightController = TextEditingController();

  WorkoutSetType _selectedType = WorkoutSetType.normal;
  bool _isSaving = false;

  @override
  void dispose() {
    _mainValueController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _setType(WorkoutSetType type) {
    setState(() {
      _selectedType = type;

      if (_selectedType == WorkoutSetType.isometric) {
        _mainValueController.text = '30';
      } else {
        _mainValueController.text = '10';
      }
    });
  }

  Future<void> _submit() async {
    if (!widget.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero inicia la sesión.')),
      );
      return;
    }

    final rawMain = _mainValueController.text.trim();
    final rawWeight = _weightController.text.trim();

    final weight = rawWeight.isEmpty ? null : double.tryParse(rawWeight);

    if (rawWeight.isNotEmpty && weight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Peso inválido.')));
      return;
    }

    int? reps;
    int? durationSeconds;

    if (_selectedType == WorkoutSetType.isometric) {
      durationSeconds = int.tryParse(rawMain);

      if (durationSeconds == null || durationSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa segundos válidos.')),
        );
        return;
      }
    } else {
      reps = int.tryParse(rawMain);

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
      _selectedType = WorkoutSetType.normal;
      _mainValueController.text = '10';
      _weightController.clear();
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSets = widget.sets.length;
    final targetSets = widget.exercise.targetSets;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Encabezado actual/meta.
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
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(
                    '$currentSets/$targetSets series',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Resumen de la última sesión.
            if (widget.previousSummary != null)
              _PreviousSessionPanel(summary: widget.previousSummary!),

            if (widget.sets.isEmpty)
              Text(
                'Aún no has guardado series hoy.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Column(
                children: List.generate(widget.sets.length, (index) {
                  return _SavedSetRow(
                    seriesIndex: index + 1,
                    set: widget.sets[index],
                  );
                }),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: _selectedType == WorkoutSetType.normal,
                  onSelected: !_isSaving
                      ? (_) => _setType(WorkoutSetType.normal)
                      : null,
                ),
                ChoiceChip(
                  label: const Text('Dropset'),
                  selected: _selectedType == WorkoutSetType.dropSet,
                  onSelected: !_isSaving
                      ? (_) => _setType(WorkoutSetType.dropSet)
                      : null,
                ),
                ChoiceChip(
                  label: const Text('Isométrico'),
                  selected: _selectedType == WorkoutSetType.isometric,
                  onSelected: !_isSaving
                      ? (_) => _setType(WorkoutSetType.isometric)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _mainValueController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: _selectedType == WorkoutSetType.isometric
                          ? 'Segundos'
                          : 'Repeticiones',
                      hintText: _selectedType == WorkoutSetType.isometric
                          ? 'Ej. 30'
                          : 'Ej. 10',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Peso',
                      hintText: 'opcional',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: FilledButton(
                    onPressed: !_isSaving ? _submit : null,
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
          ],
        ),
      ),
    );
  }
}

/// Panel de resumen de la última sesión.
///
/// ¿Qué hace?
/// Muestra de forma compacta:
/// - total de series anteriores
/// - mejor set anterior
/// - peso máximo anterior
/// - fecha de esa sesión
class _PreviousSessionPanel extends StatelessWidget {
  final ExerciseLastSessionSummary summary;

  const _PreviousSessionPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Última sesión · ${_formatDate(summary.performedAt)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text('Series: ${summary.totalSets}'),
          Text(_buildBestSetText(summary)),
          if (summary.heaviestWeight != null)
            Text('Peso más alto: ${summary.heaviestWeight} kg'),
        ],
      ),
    );
  }

  String _buildBestSetText(ExerciseLastSessionSummary summary) {
    if (summary.bestReps != null) {
      return 'Mejor set: ${summary.bestReps} reps';
    }

    if (summary.bestDurationSeconds != null) {
      return 'Mejor set: ${summary.bestDurationSeconds}s';
    }

    return 'Mejor set: sin datos';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SavedSetRow extends StatelessWidget {
  final int seriesIndex;
  final WorkoutSetEntry set;

  const _SavedSetRow({required this.seriesIndex, required this.set});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 58, child: Text('Serie $seriesIndex')),
          Expanded(child: Text(_buildSetText())),
          if (set.setType == WorkoutSetType.dropSet)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const Text('DROP'),
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
