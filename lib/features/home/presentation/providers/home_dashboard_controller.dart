import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../data/home_dashboard_repository.dart';
import '../../domain/home_dashboard_overview.dart';

/// Provider del repositorio Home.
///
/// ¿Qué hace?
/// Inyecta la implementación que compone el dashboard desde varios módulos.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la lógica real del Home premium.
final homeDashboardRepositoryProvider = Provider<HomeDashboardRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final rpgRepository = ref.watch(rpgRepositoryProvider);
  final dailyMissionRepository = ref.watch(dailyMissionRepositoryProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return HomeDashboardRepository(
    db: db,
    rpgRepository: rpgRepository,
    dailyMissionRepository: dailyMissionRepository,
    healthRepository: healthRepository,
  );
});

/// Controlador principal del dashboard Home.
///
/// ¿Qué hace?
/// Carga el resumen completo del Home.
///
/// ¿Para qué sirve?
/// Para mantener la Home declarativa y fácil de refrescar.
class HomeDashboardController extends AsyncNotifier<HomeDashboardOverview> {
  late final HomeDashboardRepository _repository;

  @override
  Future<HomeDashboardOverview> build() async {
    _repository = ref.watch(homeDashboardRepositoryProvider);
    return _repository.getOverview();
  }

  /// Recarga el dashboard principal.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getOverview);
  }
}

final homeDashboardControllerProvider =
    AsyncNotifierProvider<HomeDashboardController, HomeDashboardOverview>(
      HomeDashboardController.new,
    );
