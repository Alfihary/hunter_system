import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../domain/system_diagnostics_overview.dart';

/// Repositorio de diagnóstico del sistema.
///
/// ¿Qué hace?
/// Lee el estado real de la aplicación desde:
/// - base de datos
/// - Health
/// - configuración persistida
///
/// ¿Para qué sirve?
/// Para dar una auditoría rápida y confiable del proyecto
/// sin tener que revisar módulo por módulo manualmente.
class SystemDiagnosticsRepository {
  final AppDatabase db;
  final HealthRepository healthRepository;

  SystemDiagnosticsRepository({
    required this.db,
    required this.healthRepository,
  });

  /// Genera el overview completo de diagnóstico.
  Future<SystemDiagnosticsOverview> getOverview() async {
    final generatedAt = DateTime.now();

    final habitsCount = await _count('habits');
    final habitLogsCount = await _count('habit_logs');

    final routineCount = await _count('workout_routines');
    final workoutsCount = await _count('workouts');
    final workoutSetsCount = await _count('workout_sets');
    final finishedWorkoutsCount = await _countWhere(
      tableName: 'workouts',
      whereClause: 'ended_at IS NOT NULL',
    );

    final nutritionLogsCount = await _count('nutrition_logs');
    final hasNutritionGoal = await _existsWhere(
      tableName: 'nutrition_goals',
      whereClause: 'id = 1',
    );

    bool isHealthSupported = false;
    bool hasHealthPermissions = false;

    try {
      final healthOverview = await healthRepository.getTodayOverview();
      isHealthSupported = healthOverview.isSupportedPlatform;
      hasHealthPermissions = healthOverview.hasPermissions;
    } catch (_) {
      /// No rompemos el diagnóstico si Health falla.
      isHealthSupported = false;
      hasHealthPermissions = false;
    }

    final healthSnapshotsCount = await _count('health_daily_snapshots');

    String? lastHealthSnapshotDateKey;
    final lastSnapshot =
        await (db.select(db.healthDailySnapshots)
              ..orderBy([(table) => OrderingTerm.desc(table.dateKey)])
              ..limit(1))
            .getSingleOrNull();

    if (lastSnapshot != null) {
      lastHealthSnapshotDateKey = lastSnapshot.dateKey;
    }

    final dailyMissionClaimsCount = await _count('daily_mission_claims');
    final weeklyRewardClaimsCount = await _count('weekly_quest_reward_claims');

    final hasRpgProfileSettings = await _existsWhere(
      tableName: 'rpg_profile_settings',
      whereClause: 'id = 1',
    );

    final checks = <SystemDiagnosticCheck>[
      _buildCoreCheck(
        hasNutritionGoal: hasNutritionGoal,
        hasRpgProfileSettings: hasRpgProfileSettings,
      ),
      _buildHabitsCheck(
        habitsCount: habitsCount,
        habitLogsCount: habitLogsCount,
      ),
      _buildWorkoutCheck(
        routineCount: routineCount,
        workoutsCount: workoutsCount,
        finishedWorkoutsCount: finishedWorkoutsCount,
        workoutSetsCount: workoutSetsCount,
      ),
      _buildNutritionCheck(
        hasNutritionGoal: hasNutritionGoal,
        nutritionLogsCount: nutritionLogsCount,
      ),
      _buildHealthCheck(
        isHealthSupported: isHealthSupported,
        hasHealthPermissions: hasHealthPermissions,
        healthSnapshotsCount: healthSnapshotsCount,
        lastHealthSnapshotDateKey: lastHealthSnapshotDateKey,
      ),
      _buildQuestCheck(
        dailyMissionClaimsCount: dailyMissionClaimsCount,
        weeklyRewardClaimsCount: weeklyRewardClaimsCount,
      ),
      _buildRpgReadinessCheck(
        habitLogsCount: habitLogsCount,
        finishedWorkoutsCount: finishedWorkoutsCount,
        nutritionLogsCount: nutritionLogsCount,
        healthSnapshotsCount: healthSnapshotsCount,
        dailyMissionClaimsCount: dailyMissionClaimsCount,
      ),
    ];

    return SystemDiagnosticsOverview(
      generatedAt: generatedAt,
      habitsCount: habitsCount,
      habitLogsCount: habitLogsCount,
      routineCount: routineCount,
      workoutsCount: workoutsCount,
      finishedWorkoutsCount: finishedWorkoutsCount,
      workoutSetsCount: workoutSetsCount,
      nutritionLogsCount: nutritionLogsCount,
      hasNutritionGoal: hasNutritionGoal,
      healthSnapshotsCount: healthSnapshotsCount,
      isHealthSupported: isHealthSupported,
      hasHealthPermissions: hasHealthPermissions,
      lastHealthSnapshotDateKey: lastHealthSnapshotDateKey,
      dailyMissionClaimsCount: dailyMissionClaimsCount,
      weeklyRewardClaimsCount: weeklyRewardClaimsCount,
      hasRpgProfileSettings: hasRpgProfileSettings,
      checks: checks,
    );
  }

  /// Cuenta filas de una tabla.
  Future<int> _count(String tableName) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS count FROM $tableName')
        .getSingle();

    return _readInt(row.data['count']);
  }

  /// Cuenta filas de una tabla con condición.
  Future<int> _countWhere({
    required String tableName,
    required String whereClause,
  }) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM $tableName WHERE $whereClause',
        )
        .getSingle();

    return _readInt(row.data['count']);
  }

  /// Revisa si existe al menos una fila que cumpla una condición.
  Future<bool> _existsWhere({
    required String tableName,
    required String whereClause,
  }) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM $tableName WHERE $whereClause',
        )
        .getSingle();

    return _readInt(row.data['count']) > 0;
  }

  /// Convierte un valor dinámico a int de forma segura.
  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Diagnóstico de infraestructura base.
  SystemDiagnosticCheck _buildCoreCheck({
    required bool hasNutritionGoal,
    required bool hasRpgProfileSettings,
  }) {
    if (hasNutritionGoal && hasRpgProfileSettings) {
      return const SystemDiagnosticCheck(
        id: 'core',
        title: 'Infraestructura base',
        message: 'La configuración base crítica está inicializada.',
        severity: DiagnosticSeverity.ok,
        details:
            'nutrition_goals y rpg_profile_settings existen correctamente.',
      );
    }

    return SystemDiagnosticCheck(
      id: 'core',
      title: 'Infraestructura base',
      message: 'Falta configuración base persistida.',
      severity: DiagnosticSeverity.error,
      details:
          'nutrition_goals: $hasNutritionGoal | rpg_profile_settings: $hasRpgProfileSettings',
    );
  }

  /// Diagnóstico del módulo de hábitos.
  SystemDiagnosticCheck _buildHabitsCheck({
    required int habitsCount,
    required int habitLogsCount,
  }) {
    if (habitsCount <= 0) {
      return const SystemDiagnosticCheck(
        id: 'habits',
        title: 'Hábitos',
        message: 'El módulo existe, pero todavía no hay hábitos creados.',
        severity: DiagnosticSeverity.warning,
        details: 'Crea al menos 2 o 3 hábitos base para probar el sistema.',
      );
    }

    if (habitLogsCount <= 0) {
      return SystemDiagnosticCheck(
        id: 'habits',
        title: 'Hábitos',
        message: 'Hay hábitos creados, pero aún no hay registros completados.',
        severity: DiagnosticSeverity.warning,
        details: 'Hábitos creados: $habitsCount | Registros: $habitLogsCount',
      );
    }

    return SystemDiagnosticCheck(
      id: 'habits',
      title: 'Hábitos',
      message: 'El módulo de hábitos ya tiene datos funcionales.',
      severity: DiagnosticSeverity.ok,
      details: 'Hábitos: $habitsCount | Registros: $habitLogsCount',
    );
  }

  /// Diagnóstico del módulo de entrenamiento.
  SystemDiagnosticCheck _buildWorkoutCheck({
    required int routineCount,
    required int workoutsCount,
    required int finishedWorkoutsCount,
    required int workoutSetsCount,
  }) {
    if (routineCount <= 0) {
      return const SystemDiagnosticCheck(
        id: 'workouts',
        title: 'Entrenamiento',
        message: 'No hay rutinas creadas todavía.',
        severity: DiagnosticSeverity.warning,
        details: 'Crea al menos una rutina para validar el flujo completo.',
      );
    }

    if (finishedWorkoutsCount <= 0) {
      return SystemDiagnosticCheck(
        id: 'workouts',
        title: 'Entrenamiento',
        message: 'Hay rutinas, pero todavía no hay entrenamientos terminados.',
        severity: DiagnosticSeverity.warning,
        details:
            'Rutinas: $routineCount | Sesiones: $workoutsCount | Finalizadas: $finishedWorkoutsCount | Sets: $workoutSetsCount',
      );
    }

    return SystemDiagnosticCheck(
      id: 'workouts',
      title: 'Entrenamiento',
      message: 'El módulo de entrenamiento ya tiene sesiones útiles.',
      severity: DiagnosticSeverity.ok,
      details:
          'Rutinas: $routineCount | Sesiones: $workoutsCount | Finalizadas: $finishedWorkoutsCount | Sets: $workoutSetsCount',
    );
  }

  /// Diagnóstico del módulo de nutrición.
  SystemDiagnosticCheck _buildNutritionCheck({
    required bool hasNutritionGoal,
    required int nutritionLogsCount,
  }) {
    if (!hasNutritionGoal) {
      return const SystemDiagnosticCheck(
        id: 'nutrition',
        title: 'Nutrición',
        message: 'Falta la fila base de metas nutricionales.',
        severity: DiagnosticSeverity.error,
        details: 'Revisa migraciones o inserción inicial de nutrition_goals.',
      );
    }

    if (nutritionLogsCount <= 0) {
      return const SystemDiagnosticCheck(
        id: 'nutrition',
        title: 'Nutrición',
        message:
            'La configuración existe, pero aún no hay alimentos registrados.',
        severity: DiagnosticSeverity.warning,
        details: 'Registra comida manual, por búsqueda o por código de barras.',
      );
    }

    return SystemDiagnosticCheck(
      id: 'nutrition',
      title: 'Nutrición',
      message: 'El módulo de nutrición ya está produciendo datos.',
      severity: DiagnosticSeverity.ok,
      details: 'Registros nutricionales: $nutritionLogsCount',
    );
  }

  /// Diagnóstico del módulo Health.
  SystemDiagnosticCheck _buildHealthCheck({
    required bool isHealthSupported,
    required bool hasHealthPermissions,
    required int healthSnapshotsCount,
    required String? lastHealthSnapshotDateKey,
  }) {
    if (!isHealthSupported) {
      return const SystemDiagnosticCheck(
        id: 'health',
        title: 'Health',
        message:
            'Health no está disponible en esta plataforma o falló la lectura.',
        severity: DiagnosticSeverity.warning,
        details: 'Prueba en Android/iPhone real con permisos configurados.',
      );
    }

    if (!hasHealthPermissions) {
      return const SystemDiagnosticCheck(
        id: 'health',
        title: 'Health',
        message: 'Health está disponible, pero faltan permisos.',
        severity: DiagnosticSeverity.warning,
        details: 'Concede pasos y sueño desde la pantalla Health.',
      );
    }

    if (healthSnapshotsCount <= 0) {
      return const SystemDiagnosticCheck(
        id: 'health',
        title: 'Health',
        message: 'Hay permisos, pero aún no existen snapshots guardados.',
        severity: DiagnosticSeverity.warning,
        details: 'Entra a Health y fuerza una sincronización.',
      );
    }

    return SystemDiagnosticCheck(
      id: 'health',
      title: 'Health',
      message: 'Health ya está aportando datos persistidos.',
      severity: DiagnosticSeverity.ok,
      details:
          'Snapshots: $healthSnapshotsCount | Último snapshot: ${lastHealthSnapshotDateKey ?? 'sin fecha'}',
    );
  }

  /// Diagnóstico del sistema de misiones.
  SystemDiagnosticCheck _buildQuestCheck({
    required int dailyMissionClaimsCount,
    required int weeklyRewardClaimsCount,
  }) {
    if (dailyMissionClaimsCount <= 0) {
      return const SystemDiagnosticCheck(
        id: 'quests',
        title: 'Misiones',
        message: 'El sistema existe, pero todavía no hay misiones reclamadas.',
        severity: DiagnosticSeverity.warning,
        details: 'Completa y reclama al menos una misión diaria.',
      );
    }

    return SystemDiagnosticCheck(
      id: 'quests',
      title: 'Misiones',
      message: 'Las misiones ya están persistiendo recompensas.',
      severity: DiagnosticSeverity.ok,
      details:
          'Reclamos diarios: $dailyMissionClaimsCount | Recompensas semanales: $weeklyRewardClaimsCount',
    );
  }

  /// Diagnóstico de preparación del RPG.
  SystemDiagnosticCheck _buildRpgReadinessCheck({
    required int habitLogsCount,
    required int finishedWorkoutsCount,
    required int nutritionLogsCount,
    required int healthSnapshotsCount,
    required int dailyMissionClaimsCount,
  }) {
    final activeSources = [
      habitLogsCount > 0,
      finishedWorkoutsCount > 0,
      nutritionLogsCount > 0,
      healthSnapshotsCount > 0,
      dailyMissionClaimsCount > 0,
    ].where((value) => value).length;

    if (activeSources >= 4) {
      return SystemDiagnosticCheck(
        id: 'rpg_ready',
        title: 'RPG',
        message:
            'El RPG ya tiene suficientes fuentes activas para evaluarse bien.',
        severity: DiagnosticSeverity.ok,
        details: 'Fuentes activas: $activeSources / 5',
      );
    }

    if (activeSources >= 2) {
      return SystemDiagnosticCheck(
        id: 'rpg_ready',
        title: 'RPG',
        message:
            'El RPG funciona, pero todavía está alimentado por pocas fuentes.',
        severity: DiagnosticSeverity.warning,
        details: 'Fuentes activas: $activeSources / 5',
      );
    }

    return SystemDiagnosticCheck(
      id: 'rpg_ready',
      title: 'RPG',
      message:
          'El RPG aún no tiene suficientes datos para reflejar progreso real.',
      severity: DiagnosticSeverity.warning,
      details: 'Fuentes activas: $activeSources / 5',
    );
  }
}
