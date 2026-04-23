import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../data/derived_daily_mission_repository.dart';
import '../../domain/daily_mission.dart';
import '../../domain/daily_mission_repository.dart';
import '../../domain/weekly_quest_overview.dart';

/// Provider del repositorio de misiones.
///
/// ¿Qué hace?
/// Inyecta la implementación derivada desde BD + Health.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI del cálculo real.
final dailyMissionRepositoryProvider = Provider<DailyMissionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return DerivedDailyMissionRepository(db, healthRepository: healthRepository);
});

/// Provider principal de misiones diarias.
final todayDailyMissionsProvider = FutureProvider<List<DailyMission>>((ref) {
  final repository = ref.watch(dailyMissionRepositoryProvider);
  return repository.getTodayMissions();
});

/// Provider principal del tablero semanal.
final currentWeekQuestOverviewProvider = FutureProvider<WeeklyQuestOverview>((
  ref,
) {
  final repository = ref.watch(dailyMissionRepositoryProvider);
  return repository.getCurrentWeekOverview();
});

/// Controlador de acciones sobre misiones.
///
/// ¿Qué hace?
/// Maneja:
/// - reclamos de misiones diarias
/// - reclamos de recompensas semanales
///
/// ¿Para qué sirve?
/// Para evitar lógica mutante dentro de la UI.
class DailyMissionActionController extends AsyncNotifier<void> {
  late final DailyMissionRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(dailyMissionRepositoryProvider);
  }

  /// Reclama una misión diaria.
  Future<String?> claimMission(String missionId) async {
    state = const AsyncLoading();

    try {
      await _repository.claimMission(missionId);

      ref.invalidate(todayDailyMissionsProvider);
      ref.invalidate(currentWeekQuestOverviewProvider);
      ref.invalidate(rpgAchievementsProvider);
      ref.invalidate(rpgTitlesProvider);
      await ref.read(rpgControllerProvider.notifier).reload();

      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  /// Reclama una recompensa semanal.
  Future<String?> claimWeeklyReward(String rewardId) async {
    state = const AsyncLoading();

    try {
      await _repository.claimWeeklyReward(rewardId);

      ref.invalidate(todayDailyMissionsProvider);
      ref.invalidate(currentWeekQuestOverviewProvider);
      ref.invalidate(rpgAchievementsProvider);
      ref.invalidate(rpgTitlesProvider);
      await ref.read(rpgControllerProvider.notifier).reload();

      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }
}

final dailyMissionActionControllerProvider =
    AsyncNotifierProvider<DailyMissionActionController, void>(
      DailyMissionActionController.new,
    );
