import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../features/health/domain/health_repository.dart';
import '../domain/app_bootstrap_result.dart';

/// Servicio de arranque seguro de la aplicación.
///
/// ¿Qué hace?
/// Ejecuta verificaciones mínimas antes de permitir el acceso normal:
/// - asegura filas base críticas
/// - intenta sincronizar Health si ya hay permisos
///
/// ¿Para qué sirve?
/// Para reducir errores de primer arranque y dejar el sistema
/// en un estado estable antes de navegar a Login o Home.
class AppBootstrapService {
  final AppDatabase db;
  final HealthRepository healthRepository;

  const AppBootstrapService({required this.db, required this.healthRepository});

  /// Ejecuta el bootstrap completo.
  Future<AppBootstrapResult> run() async {
    final warnings = <String>[];

    final baseReady = await _ensureBaseConfiguration();

    bool healthSyncAttempted = false;
    bool healthSyncSucceeded = false;

    try {
      final healthSupported = await _isHealthSupported();
      if (healthSupported) {
        final hasPermissions = await healthRepository.hasPermissions();

        if (hasPermissions) {
          healthSyncAttempted = true;
          await healthRepository.syncTodayToCache();
          healthSyncSucceeded = true;
        } else {
          warnings.add(
            'Health está disponible pero todavía no tiene permisos concedidos.',
          );
        }
      } else {
        warnings.add(
          'Health no está disponible en esta plataforma o no pudo inicializarse.',
        );
      }
    } catch (e) {
      healthSyncAttempted = true;
      healthSyncSucceeded = false;
      warnings.add('No se pudo sincronizar Health durante el arranque: $e');
    }

    return AppBootstrapResult(
      completedAt: DateTime.now(),
      baseConfigurationReady: baseReady,
      healthSyncAttempted: healthSyncAttempted,
      healthSyncSucceeded: healthSyncSucceeded,
      warnings: warnings,
    );
  }

  /// Asegura que existan las filas base mínimas del sistema.
  ///
  /// ¿Qué hace?
  /// Inserta, si faltan:
  /// - nutrition_goals con id = 1
  /// - rpg_profile_settings con id = 1
  ///
  /// ¿Para qué sirve?
  /// Para evitar fallos en módulos que dependen de configuración inicial.
  Future<bool> _ensureBaseConfiguration() async {
    try {
      await db
          .into(db.nutritionGoals)
          .insert(
            const NutritionGoalsCompanion(
              id: Value(1),
              caloriesGoal: Value(2200.0),
              proteinGoal: Value(160.0),
              carbsGoal: Value(200.0),
              fatsGoal: Value(70.0),
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

      return nutritionGoalExists != null && rpgSettingsExists != null;
    } catch (_) {
      return false;
    }
  }

  /// Revisa si Health puede consultarse en este dispositivo.
  Future<bool> _isHealthSupported() async {
    try {
      final overview = await healthRepository.getTodayOverview();
      return overview.isSupportedPlatform;
    } catch (_) {
      return false;
    }
  }
}
