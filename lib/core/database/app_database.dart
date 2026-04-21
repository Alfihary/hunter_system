import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// ==============================
/// TABLAS DE HÁBITOS
/// ==============================

/// Tabla principal de hábitos.
///
/// Guarda la definición base del hábito.
class Habits extends Table {
  /// ID único del hábito.
  TextColumn get id => text()();

  /// Nombre visible del hábito.
  TextColumn get name => text().withLength(min: 2, max: 60)();

  /// Categoría guardada como texto.
  TextColumn get category => text()();

  /// XP otorgado al completar el hábito.
  IntColumn get xpReward => integer().withDefault(const Constant(10))();

  /// Si el hábito sigue activo.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha de creación.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Historial diario de cumplimiento de hábitos.
class HabitLogs extends Table {
  /// ID único del log.
  TextColumn get id => text()();

  /// Relación con el hábito.
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Fecha simplificada, ejemplo: 2026-04-20
  TextColumn get dateKey => text()();

  /// Fecha/hora exacta del registro.
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==============================
/// TABLAS DE ENTRENAMIENTO
/// ==============================

/// Rutinas base de entrenamiento.
///
/// Sirven como plantillas reutilizables.
class WorkoutRoutines extends Table {
  /// ID único de la rutina.
  TextColumn get id => text()();

  /// Nombre visible.
  TextColumn get name => text().withLength(min: 2, max: 80)();

  /// Descripción opcional.
  TextColumn get description => text().nullable()();

  /// Indica si la rutina sigue activa.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha de creación.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ejercicios pertenecientes a una rutina.
///
/// Ahora incluye `targetSets` para mostrar en sesión:
/// - 0/4 series
/// - 1/4 series
/// - 4/4 series
class RoutineExercises extends Table {
  /// ID único del ejercicio dentro de la rutina.
  TextColumn get id => text()();

  /// Relación con la rutina.
  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  /// Nombre del ejercicio.
  TextColumn get name => text().withLength(min: 2, max: 80)();

  /// Grupo muscular guardado como texto.
  TextColumn get muscleGroup => text()();

  /// Orden visual del ejercicio dentro de la rutina.
  IntColumn get sortOrder => integer()();

  /// Meta de series planeadas para el ejercicio.
  IntColumn get targetSets => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sesión real de entrenamiento.
///
/// Se crea cuando el usuario empieza a entrenar.
class Workouts extends Table {
  /// ID único de la sesión.
  TextColumn get id => text()();

  /// Rutina de origen.
  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  /// Inicio de la sesión.
  DateTimeColumn get startedAt => dateTime()();

  /// Fin de la sesión.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Notas opcionales.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sets ejecutados dentro de una sesión.
///
/// Soporta:
/// - normal
/// - dropSet
/// - isometric
class WorkoutSets extends Table {
  /// ID único del set.
  TextColumn get id => text()();

  /// Relación con la sesión.
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();

  /// Nombre del ejercicio al momento de guardar.
  TextColumn get exerciseNameSnapshot => text()();

  /// Grupo muscular al momento de guardar.
  TextColumn get muscleGroupSnapshot => text()();

  /// Repeticiones.
  ///
  /// Nulo en sets isométricos.
  IntColumn get reps => integer().nullable()();

  /// Duración en segundos.
  ///
  /// Se usa sólo para isométricos.
  IntColumn get durationSeconds => integer().nullable()();

  /// Peso opcional.
  RealColumn get weight => real().nullable()();

  /// Tipo de set:
  /// - normal
  /// - dropSet
  /// - isometric
  TextColumn get setType => text().withDefault(const Constant('normal'))();

  /// Orden del set dentro de la sesión.
  IntColumn get setOrder => integer()();

  /// Fecha/hora de creación.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Base de datos principal de la app.
///
/// Centraliza todas las tablas y define las migraciones.
@DriftDatabase(
  tables: [
    Habits,
    HabitLogs,
    WorkoutRoutines,
    RoutineExercises,
    Workouts,
    WorkoutSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Versión actual del esquema.
  ///
  /// v1 = hábitos
  /// v2 = entrenamiento base
  /// v3 = cambio de estructura en workout_sets
  /// v4 = targetSets en routine_exercises
  @override
  int get schemaVersion => 4;

  /// Estrategia de migración.
  ///
  /// En esta etapa de desarrollo preferimos migraciones simples y seguras
  /// para evitar conflictos con archivos generados viejos.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(workoutRoutines);
        await m.createTable(routineExercises);
        await m.createTable(workouts);
        await m.createTable(workoutSets);
      }

      if (from < 3) {
        /// Recreamos workout_sets porque cambió su estructura.
        await m.deleteTable('workout_sets');
        await m.createTable(workoutSets);
      }

      if (from < 4) {
        /// En desarrollo es más simple recrear esta tabla
        /// que pelear con addColumn + código generado viejo.
        await m.deleteTable('routine_exercises');
        await m.createTable(routineExercises);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'hunter_system',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
