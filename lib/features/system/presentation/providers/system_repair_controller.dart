import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../data/system_repair_repository.dart';
import '../../domain/system_repair_result.dart';
import 'system_diagnostics_controller.dart';

/// Provider del repositorio de reparación.
///
/// ¿Qué hace?
/// Inyecta la capa que corrige problemas comunes del sistema.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la lógica correctiva.
final systemRepairRepositoryProvider = Provider<SystemRepairRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return SystemRepairRepository(db: db, healthRepository: healthRepository);
});

/// Controlador de reparación del sistema.
///
/// ¿Qué hace?
/// Ejecuta acciones correctivas y refresca módulos relacionados.
///
/// ¿Para qué sirve?
/// Para evitar lógica mutante dentro de la pantalla de diagnóstico.
class SystemRepairController extends AsyncNotifier<void> {
  late final SystemRepairRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(systemRepairRepositoryProvider);
  }

  /// Repara la configuración base crítica.
  Future<SystemRepairResult> ensureBaseConfiguration() async {
    state = const AsyncLoading();

    try {
      final result = await _repository.ensureBaseConfiguration();
      _invalidateRelatedProviders();
      state = const AsyncData(null);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return SystemRepairResult(success: false, message: e.toString());
    }
  }

  /// Crea hábitos recomendados del sistema.
  Future<SystemRepairResult> seedRecommendedHabits() async {
    state = const AsyncLoading();

    try {
      final result = await _repository.seedRecommendedHabits();
      _invalidateRelatedProviders();
      state = const AsyncData(null);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return SystemRepairResult(success: false, message: e.toString());
    }
  }

  /// Sincroniza Health inmediatamente.
  Future<SystemRepairResult> syncHealthNow() async {
    state = const AsyncLoading();

    try {
      final result = await _repository.syncHealthNow();
      _invalidateRelatedProviders();
      state = const AsyncData(null);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return SystemRepairResult(success: false, message: e.toString());
    }
  }

  /// Refresca providers relacionados después de una reparación.
  void _invalidateRelatedProviders() {
    ref.invalidate(systemDiagnosticsOverviewProvider);
    ref.invalidate(healthControllerProvider);
    ref.invalidate(todayDailyMissionsProvider);
    ref.invalidate(currentWeekQuestOverviewProvider);
    ref.invalidate(rpgControllerProvider);
    ref.invalidate(rpgAchievementsProvider);
    ref.invalidate(rpgTitlesProvider);
  }
}

final systemRepairControllerProvider =
    AsyncNotifierProvider<SystemRepairController, void>(
      SystemRepairController.new,
    );
