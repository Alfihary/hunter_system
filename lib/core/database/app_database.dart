import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// ==============================
/// TABLAS DE HÁBITOS
/// ==============================

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

class WorkoutRoutines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 2, max: 80)();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineExercises extends Table {
  TextColumn get id => text()();

  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 2, max: 80)();
  TextColumn get muscleGroup => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}

class Workouts extends Table {
  TextColumn get id => text()();

  TextColumn get routineId =>
      text().references(WorkoutRoutines, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSets extends Table {
  TextColumn get id => text()();

  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();

  TextColumn get exerciseNameSnapshot => text()();
  TextColumn get muscleGroupSnapshot => text()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get weight => real().nullable()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  IntColumn get setOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ==============================
/// TABLAS DE NUTRICIÓN
/// ==============================

/// Metas globales de nutrición.
///
/// ¿Qué hace?
/// Guarda una sola fila con las metas nutricionales del usuario.
///
/// ¿Para qué sirve?
/// Para tener objetivos diarios reutilizables en el resumen de nutrición.
class NutritionGoals extends Table {
  IntColumn get id => integer()();
  RealColumn get caloriesGoal => real()();
  RealColumn get proteinGoal => real()();
  RealColumn get carbsGoal => real()();
  RealColumn get fatsGoal => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Registros individuales de alimentos o comidas.
///
/// ¿Qué hace?
/// Guarda el snapshot nutricional de cada alimento registrado.
///
/// ¿Para qué sirve?
/// Para el historial diario y, más adelante,
/// para conectar el RPG a la alimentación real.
class NutritionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get foodName => text().withLength(min: 1, max: 120)();
  TextColumn get mealType => text()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  TextColumn get servingDescription => text().nullable()();
  TextColumn get externalId => text().nullable()();
  RealColumn get calories => real().withDefault(const Constant(0))();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get fats => real().withDefault(const Constant(0))();
  DateTimeColumn get loggedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Habits,
    HabitLogs,
    WorkoutRoutines,
    RoutineExercises,
    Workouts,
    WorkoutSets,
    NutritionGoals,
    NutritionLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Subimos a 5 porque agregamos tablas de nutrición.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      await customStatement('''
            INSERT OR IGNORE INTO nutrition_goals
            (id, calories_goal, protein_goal, carbs_goal, fats_goal)
            VALUES (1, 2200, 160, 200, 70)
          ''');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(workoutRoutines);
        await m.createTable(routineExercises);
        await m.createTable(workouts);
        await m.createTable(workoutSets);
      }

      if (from < 3) {
        await m.deleteTable('workout_sets');
        await m.createTable(workoutSets);
      }

      if (from < 4) {
        await m.addColumn(routineExercises, routineExercises.targetSets);
      }

      if (from < 5) {
        await m.createTable(nutritionGoals);
        await m.createTable(nutritionLogs);

        await customStatement('''
              INSERT OR IGNORE INTO nutrition_goals
              (id, calories_goal, protein_goal, carbs_goal, fats_goal)
              VALUES (1, 2200, 160, 200, 70)
            ''');
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
