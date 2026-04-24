import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../domain/system_repair_result.dart';

/// Repositorio de reparación del sistema.
///
/// ¿Qué hace?
/// Ejecuta acciones correctivas sobre la app, por ejemplo:
/// - asegurar filas base críticas
/// - sembrar hábitos recomendados
/// - sincronizar Health bajo demanda
///
/// ¿Para qué sirve?
/// Para estabilizar el proyecto sin depender siempre
/// de correcciones manuales en base de datos.
class SystemRepairRepository {
  final AppDatabase db;
  final HealthRepository healthRepository;

  SystemRepairRepository({required this.db, required this.healthRepository});

  /// Repara la configuración base crítica del sistema.
  ///
  /// ¿Qué hace?
  /// Garantiza que existan:
  /// - nutrition_goals con id = 1
  /// - rpg_profile_settings con id = 1
  ///
  /// ¿Para qué sirve?
  /// Para evitar fallos en módulos que esperan configuración base.
  Future<SystemRepairResult> ensureBaseConfiguration() async {
    await db
        .into(db.nutritionGoals)
        .insert(
          NutritionGoalsCompanion.insert(
            id: Value(1),
            caloriesGoal: 2200.0,
            proteinGoal: 160.0,
            carbsGoal: 200.0,
            fatsGoal: 70.0,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    await db
        .into(db.rpgProfileSettings)
        .insert(
          const RpgProfileSettingsCompanion(
            id: Value(1),
            equippedTitleId: Value.absent(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    final nutritionGoalExists = await (db.select(
      db.nutritionGoals,
    )..where((table) => table.id.equals(1))).getSingleOrNull();

    final rpgSettingsExists = await (db.select(
      db.rpgProfileSettings,
    )..where((table) => table.id.equals(1))).getSingleOrNull();

    if (nutritionGoalExists != null && rpgSettingsExists != null) {
      return const SystemRepairResult(
        success: true,
        message: 'Configuración base verificada y reparada correctamente.',
      );
    }

    return const SystemRepairResult(
      success: false,
      message: 'No se pudo asegurar toda la configuración base.',
    );
  }

  /// Crea hábitos recomendados para que las misiones funcionen mejor.
  ///
  /// ¿Qué hace?
  /// Inserta, si no existen ya, hábitos equivalentes a:
  /// - Despertar sin celular
  /// - Bloque de enfoque
  /// - Rutina facial
  ///
  /// ¿Para qué sirve?
  /// Para que el sistema de misiones tenga de dónde alimentarse.
  Future<SystemRepairResult> seedRecommendedHabits() async {
    final existingHabits = await db.select(db.habits).get();
    final now = DateTime.now();

    final seeds = <_StarterHabitSeed>[
      _StarterHabitSeed(
        name: 'Despertar sin celular',
        category: 'Disciplina',
        xpReward: 20,
        tokens: const [
          'sin celular',
          'no celular',
          'despertar sin celular',
          'no redes',
        ],
      ),
      _StarterHabitSeed(
        name: 'Bloque de enfoque',
        category: 'Mental',
        xpReward: 20,
        tokens: const ['enfoque', 'focus', 'bloque', 'pomodoro'],
      ),
      _StarterHabitSeed(
        name: 'Rutina facial',
        category: 'Apariencia',
        xpReward: 15,
        tokens: const ['facial', 'rostro', 'cara', 'grooming', 'skin'],
      ),
    ];

    int created = 0;
    int skipped = 0;

    for (int index = 0; index < seeds.length; index++) {
      final seed = seeds[index];

      final exists = existingHabits.any(
        (habit) =>
            _containsAnyToken('${habit.name} ${habit.category}', seed.tokens),
      );

      if (exists) {
        skipped++;
        continue;
      }

      final id =
          'starter_${_slugify(seed.name)}_${now.microsecondsSinceEpoch}_$index';

      await db
          .into(db.habits)
          .insert(
            HabitsCompanion.insert(
              id: id,
              name: seed.name,
              category: seed.category,
              createdAt: now,
              xpReward: Value(seed.xpReward),
              isActive: const Value(true),
            ),
          );

      created++;
    }

    return SystemRepairResult(
      success: true,
      message:
          'Hábitos recomendados procesados. Creados: $created | Ya existían: $skipped.',
    );
  }

  /// Sincroniza Health bajo demanda.
  ///
  /// ¿Qué hace?
  /// Intenta leer Health y guardar el snapshot del día actual.
  ///
  /// ¿Para qué sirve?
  /// Para estabilizar pruebas de pasos y sueño sin esperar
  /// a que otro módulo lo dispare.
  Future<SystemRepairResult> syncHealthNow() async {
    final overview = await healthRepository.getTodayOverview();

    if (!overview.isSupportedPlatform) {
      return const SystemRepairResult(
        success: false,
        message:
            'Health no está disponible en esta plataforma o no pudo leerse.',
      );
    }

    if (!overview.hasPermissions) {
      return const SystemRepairResult(
        success: false,
        message:
            'Health está disponible, pero faltan permisos para pasos y sueño.',
      );
    }

    await healthRepository.syncTodayToCache();

    return SystemRepairResult(
      success: true,
      message:
          'Health sincronizado. Pasos: ${overview.steps.steps} | Sueño: ${overview.sleep.totalHours.toStringAsFixed(1)} h',
    );
  }

  /// Revisa si un texto contiene alguno de los tokens dados.
  bool _containsAnyToken(String source, List<String> tokens) {
    final normalized = source.toLowerCase();

    for (final token in tokens) {
      if (normalized.contains(token.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Convierte texto a un slug simple.
  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

/// Semilla de hábito recomendado.
class _StarterHabitSeed {
  final String name;
  final String category;
  final int xpReward;
  final List<String> tokens;

  const _StarterHabitSeed({
    required this.name,
    required this.category,
    required this.xpReward,
    required this.tokens,
  });
}
