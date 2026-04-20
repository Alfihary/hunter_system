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
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 2, max: 60)();
  TextColumn get category => text()();
  IntColumn get xpReward => integer().withDefault(const Constant(10))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Historial diario de cumplimiento de hábitos.
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get dateKey => text()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==============================
/// TABLAS DE ENTRENAMIENTO
/// ==============================

/// Tabla de rutinas.
///
/// ¿Qué hace?
/// Guarda la rutina como entidad principal.
///
/// ¿Para qué sirve?
/// Para que el usuario tenga plantillas reutilizables de entrenamiento.
class WorkoutRoutines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 2, max: 80)();

  /// Descripción opcional de la rutina.
  TextColumn get description => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ejercicios pertenecientes a una rutina.
///
/// ¿Qué hace?
/// Guarda la lista ordenada de ejercicios de cada rutina.
///
/// ¿Para qué sirve?
/// Para construir la sesión de entrenamiento a partir de una rutina.
class RoutineExercises extends Table {
  TextColumn get id => text()();

  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 2, max: 80)();

  /// Grupo muscular guardado como texto.
  TextColumn get muscleGroup => text()();

  /// Orden visual dentro de la rutina.
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sesión de entrenamiento real.
///
/// ¿Qué hace?
/// Registra cada entrenamiento ejecutado por el usuario.
///
/// ¿Para qué sirve?
/// Para separar "rutina plantilla" de "entrenamiento realizado".
class Workouts extends Table {
  TextColumn get id => text()();

  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startedAt => dateTime()();

  /// Momento de finalización. Nulo mientras la sesión sigue abierta.
  DateTimeColumn get endedAt => dateTime().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sets ejecutados dentro de una sesión.
///
/// ¿Qué hace?
/// Guarda el trabajo real que hizo el usuario en cada set.
///
/// ¿Para qué sirve?
/// Para registrar diferentes tipos de ejecución:
/// - set normal
/// - dropset
/// - set isométrico
///
/// Reglas del modelo:
/// - normal -> usa reps
/// - dropSet -> usa reps
/// - isometric -> usa durationSeconds
class WorkoutSets extends Table {
  /// ID único del set.
  TextColumn get id => text()();

  /// Relación con la sesión.
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();

  /// Nombre del ejercicio al momento de guardar el set.
  TextColumn get exerciseNameSnapshot => text()();

  /// Grupo muscular al momento de guardar el set.
  TextColumn get muscleGroupSnapshot => text()();

  /// Repeticiones realizadas.
  ///
  /// Será nulo para sets isométricos.
  IntColumn get reps => integer().nullable()();

  /// Duración en segundos.
  ///
  /// Se usa sólo para sets isométricos.
  IntColumn get durationSeconds => integer().nullable()();

  /// Peso opcional.
  ///
  /// En calistenia o ejercicios sin carga externa puede quedar nulo.
  RealColumn get weight => real().nullable()();

  /// Tipo de set:
  /// - normal
  /// - dropSet
  /// - isometric
  TextColumn get setType => text().withDefault(const Constant('normal'))();

  /// Orden secuencial del set dentro de la sesión.
  IntColumn get setOrder => integer()();

  /// Momento exacto de creación.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
/// Base de datos principal de la app.
///
/// ¿Qué hace?
/// Registra todas las tablas y define migraciones.
///
/// ¿Para qué sirve?
/// Para centralizar el acceso a SQLite con Drift.
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

  /// Subimos a 2 porque agregamos las tablas de entrenamiento.
  @override
  int get schemaVersion => 3;

  /// Estrategia de migración.
///
/// Nota importante:
/// En esta fase vamos a recrear únicamente la tabla `workout_sets`
/// porque cambiamos su estructura:
/// - quitamos `isDropSet`
/// - agregamos `setType`
/// - agregamos `durationSeconds`
/// - hacemos `reps` nullable
///
/// Esto conserva el resto de tablas del módulo workout.
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
          /// Recreamos únicamente la tabla de sets.
          ///
          /// Esto es práctico en etapa de desarrollo.
          /// Si después quisieras preservar todos los sets existentes,
          /// habría que hacer una migración más fina.
          await m.deleteTable('workout_sets');
          await m.createTable(workoutSets);
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