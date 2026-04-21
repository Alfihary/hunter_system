import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/exercise_last_session_summary.dart';
import '../domain/muscle_group.dart';
import '../domain/routine_exercise_input.dart';
import '../domain/workout_history_detail.dart';
import '../domain/workout_history_item.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_routine_detail.dart';
import '../domain/workout_routine_summary.dart';
import '../domain/workout_set_entry.dart';
import '../domain/workout_set_type.dart';

/// Implementación real del módulo de entrenamiento usando Drift.
///
/// ¿Qué hace?
/// Lee y escribe rutinas, sesiones y sets en SQLite.
///
/// ¿Para qué sirve?
/// Para encapsular toda la persistencia local del entrenamiento.
class DriftWorkoutRepository implements WorkoutRepository {
  final AppDatabase db;

  DriftWorkoutRepository(this.db);

  @override
  Future<List<WorkoutRoutineSummary>> getRoutineSummaries() async {
    final routineRows =
        await (db.select(db.workoutRoutines)
              ..where((table) => table.isActive.equals(true))
              ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
            .get();

    final exerciseRows = await db.select(db.routineExercises).get();

    return routineRows.map((routine) {
      final exerciseCount = exerciseRows
          .where((exercise) => exercise.routineId == routine.id)
          .length;

      return WorkoutRoutineSummary(
        id: routine.id,
        name: routine.name,
        description: routine.description,
        exerciseCount: exerciseCount,
      );
    }).toList();
  }

  @override
  Future<WorkoutRoutineDetail?> getRoutineDetail(String routineId) async {
    final routine = await (db.select(
      db.workoutRoutines,
    )..where((table) => table.id.equals(routineId))).getSingleOrNull();

    if (routine == null) return null;

    final exerciseRows =
        await (db.select(db.routineExercises)
              ..where((table) => table.routineId.equals(routineId))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();

    return WorkoutRoutineDetail(
      id: routine.id,
      name: routine.name,
      description: routine.description,
      exercises: exerciseRows
          .map(
            (row) => RoutineExerciseInput(
              name: row.name,
              muscleGroup: MuscleGroup.fromStorage(row.muscleGroup),
              targetSets: row.targetSets,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> createRoutine({
    required String name,
    String? description,
    required List<RoutineExerciseInput> exercises,
  }) async {
    final now = DateTime.now();
    final routineId = now.microsecondsSinceEpoch.toString();
    final cleanedDescription =
        (description == null || description.trim().isEmpty)
        ? null
        : description.trim();

    await db.transaction(() async {
      await db
          .into(db.workoutRoutines)
          .insert(
            WorkoutRoutinesCompanion.insert(
              id: routineId,
              name: name.trim(),
              description: cleanedDescription == null
                  ? const Value.absent()
                  : Value(cleanedDescription),
              createdAt: now,
            ),
          );

      await db.batch((batch) {
        for (int index = 0; index < exercises.length; index++) {
          final exercise = exercises[index];

          batch.insert(
            db.routineExercises,
            RoutineExercisesCompanion.insert(
              id: '${routineId}_$index',
              routineId: routineId,
              name: exercise.name.trim(),
              muscleGroup: exercise.muscleGroup.name,
              sortOrder: index,
              targetSets: Value(exercise.targetSets),
            ),
          );
        }
      });
    });
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await (db.delete(
      db.workoutRoutines,
    )..where((table) => table.id.equals(routineId))).go();
  }

  @override
  Future<String> startWorkout(String routineId) async {
    final now = DateTime.now();
    final workoutId = now.microsecondsSinceEpoch.toString();

    await db
        .into(db.workouts)
        .insert(
          WorkoutsCompanion.insert(
            id: workoutId,
            routineId: routineId,
            startedAt: now,
          ),
        );

    return workoutId;
  }

  @override
  Future<void> addWorkoutSet({
    required String workoutId,
    required String exerciseName,
    required String muscleGroup,
    required WorkoutSetType setType,
    int? reps,
    int? durationSeconds,
    double? weight,
  }) async {
    if (setType.requiresReps) {
      if (reps == null || reps <= 0) {
        throw ArgumentError('Este tipo de set requiere repeticiones válidas.');
      }
    }

    if (setType.requiresDuration) {
      if (durationSeconds == null || durationSeconds <= 0) {
        throw ArgumentError(
          'El set isométrico requiere duración válida en segundos.',
        );
      }
    }

    if (setType == WorkoutSetType.isometric && reps != null) {
      throw ArgumentError('Un set isométrico no debe guardar repeticiones.');
    }

    if (setType != WorkoutSetType.isometric && durationSeconds != null) {
      throw ArgumentError('Sólo los sets isométricos deben guardar duración.');
    }

    final existingSets = await (db.select(
      db.workoutSets,
    )..where((table) => table.workoutId.equals(workoutId))).get();

    final nextOrder = existingSets.length + 1;
    final now = DateTime.now();

    await db
        .into(db.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            id: '${workoutId}_$nextOrder',
            workoutId: workoutId,
            exerciseNameSnapshot: exerciseName.trim(),
            muscleGroupSnapshot: muscleGroup,
            reps: reps == null ? const Value.absent() : Value(reps),
            durationSeconds: durationSeconds == null
                ? const Value.absent()
                : Value(durationSeconds),
            weight: weight == null ? const Value.absent() : Value(weight),
            setType: Value(setType.name),
            setOrder: nextOrder,
            createdAt: now,
          ),
        );
  }

  @override
  Stream<List<WorkoutSetEntry>> watchWorkoutSets(String workoutId) {
    final query = db.select(db.workoutSets)
      ..where((table) => table.workoutId.equals(workoutId))
      ..orderBy([(table) => OrderingTerm.asc(table.setOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return WorkoutSetEntry(
          id: row.id,
          exerciseName: row.exerciseNameSnapshot,
          muscleGroup: row.muscleGroupSnapshot,
          setType: WorkoutSetType.fromStorage(row.setType),
          reps: row.reps,
          durationSeconds: row.durationSeconds,
          weight: row.weight,
          setOrder: row.setOrder,
          createdAt: row.createdAt,
        );
      }).toList();
    });
  }

  @override
  Future<Map<String, ExerciseLastSessionSummary>> getLastSessionComparison(
    String routineId,
  ) async {
    final lastCompletedWorkout =
        await (db.select(db.workouts)
              ..where((table) => table.routineId.equals(routineId))
              ..where((table) => table.endedAt.isNotNull())
              ..orderBy([(table) => OrderingTerm.desc(table.endedAt)])
              ..limit(1))
            .getSingleOrNull();

    if (lastCompletedWorkout == null || lastCompletedWorkout.endedAt == null) {
      return {};
    }

    final setRows =
        await (db.select(db.workoutSets)
              ..where(
                (table) => table.workoutId.equals(lastCompletedWorkout.id),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.setOrder)]))
            .get();

    final result = <String, ExerciseLastSessionSummary>{};

    for (final row in setRows) {
      final existing = result[row.exerciseNameSnapshot];

      if (existing == null) {
        result[row.exerciseNameSnapshot] = ExerciseLastSessionSummary(
          exerciseName: row.exerciseNameSnapshot,
          performedAt: lastCompletedWorkout.endedAt!,
          totalSets: 1,
          bestReps: row.reps,
          bestDurationSeconds: row.durationSeconds,
          heaviestWeight: row.weight,
        );
        continue;
      }

      result[row.exerciseNameSnapshot] = ExerciseLastSessionSummary(
        exerciseName: existing.exerciseName,
        performedAt: existing.performedAt,
        totalSets: existing.totalSets + 1,
        bestReps: _maxInt(existing.bestReps, row.reps),
        bestDurationSeconds: _maxInt(
          existing.bestDurationSeconds,
          row.durationSeconds,
        ),
        heaviestWeight: _maxDouble(existing.heaviestWeight, row.weight),
      );
    }

    return result;
  }

  @override
  Future<List<WorkoutHistoryItem>> getCompletedWorkouts() async {
    final workoutRows =
        await (db.select(db.workouts)
              ..where((table) => table.endedAt.isNotNull())
              ..orderBy([(table) => OrderingTerm.desc(table.endedAt)]))
            .get();

    if (workoutRows.isEmpty) return [];

    final routineRows = await db.select(db.workoutRoutines).get();
    final setRows = await db.select(db.workoutSets).get();

    return workoutRows.where((workout) => workout.endedAt != null).map((
      workout,
    ) {
      final routine = routineRows.firstWhere(
        (row) => row.id == workout.routineId,
      );

      final workoutSets = setRows
          .where((set) => set.workoutId == workout.id)
          .toList();

      final totalVolume = workoutSets.fold<double>(0, (sum, set) {
        if (set.reps != null && set.weight != null) {
          return sum + (set.reps! * set.weight!);
        }
        return sum;
      });

      return WorkoutHistoryItem(
        workoutId: workout.id,
        routineId: workout.routineId,
        routineName: routine.name,
        startedAt: workout.startedAt,
        endedAt: workout.endedAt!,
        totalSets: workoutSets.length,
        totalVolume: totalVolume,
      );
    }).toList();
  }

  @override
  Future<WorkoutHistoryDetail?> getWorkoutHistoryDetail(
    String workoutId,
  ) async {
    final workout = await (db.select(
      db.workouts,
    )..where((table) => table.id.equals(workoutId))).getSingleOrNull();

    if (workout == null || workout.endedAt == null) return null;

    final routine = await (db.select(
      db.workoutRoutines,
    )..where((table) => table.id.equals(workout.routineId))).getSingleOrNull();

    if (routine == null) return null;

    final setRows =
        await (db.select(db.workoutSets)
              ..where((table) => table.workoutId.equals(workoutId))
              ..orderBy([(table) => OrderingTerm.asc(table.setOrder)]))
            .get();

    final totalVolume = setRows.fold<double>(0, (sum, set) {
      if (set.reps != null && set.weight != null) {
        return sum + (set.reps! * set.weight!);
      }
      return sum;
    });

    final grouped = <String, List<WorkoutHistorySetEntry>>{};
    final muscleByExercise = <String, String>{};

    for (final row in setRows) {
      grouped.putIfAbsent(row.exerciseNameSnapshot, () => []);
      muscleByExercise[row.exerciseNameSnapshot] = row.muscleGroupSnapshot;

      grouped[row.exerciseNameSnapshot]!.add(
        WorkoutHistorySetEntry(
          setOrder: row.setOrder,
          setType: WorkoutSetType.fromStorage(row.setType),
          reps: row.reps,
          durationSeconds: row.durationSeconds,
          weight: row.weight,
          createdAt: row.createdAt,
        ),
      );
    }

    final exercises = grouped.entries.map((entry) {
      return WorkoutHistoryExerciseGroup(
        exerciseName: entry.key,
        muscleGroup: muscleByExercise[entry.key] ?? '',
        sets: entry.value,
      );
    }).toList();

    return WorkoutHistoryDetail(
      workoutId: workout.id,
      routineName: routine.name,
      startedAt: workout.startedAt,
      endedAt: workout.endedAt!,
      totalSets: setRows.length,
      totalVolume: totalVolume,
      exercises: exercises,
    );
  }

  @override
  Future<void> finishWorkout(String workoutId) async {
    await (db.update(db.workouts)..where((table) => table.id.equals(workoutId)))
        .write(WorkoutsCompanion(endedAt: Value(DateTime.now())));
  }

  int? _maxInt(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  double? _maxDouble(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }
}
