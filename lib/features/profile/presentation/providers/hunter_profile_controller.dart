import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../profile/data/hunter_profile_repository.dart';
import '../../../profile/domain/hunter_profile_overview.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';

/// Provider del repositorio del perfil.
///
/// ¿Qué hace?
/// Inyecta la implementación que compone el perfil desde varios módulos.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la lógica real del perfil.
final hunterProfileRepositoryProvider = Provider<HunterProfileRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final rpgRepository = ref.watch(rpgRepositoryProvider);
  final dailyMissionRepository = ref.watch(dailyMissionRepositoryProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return HunterProfileRepository(
    db: db,
    rpgRepository: rpgRepository,
    dailyMissionRepository: dailyMissionRepository,
    healthRepository: healthRepository,
  );
});

/// Controlador principal del perfil.
///
/// ¿Qué hace?
/// Carga el resumen completo del perfil del cazador.
///
/// ¿Para qué sirve?
/// Para mantener la pantalla declarativa y fácil de refrescar.
class HunterProfileController extends AsyncNotifier<HunterProfileOverview> {
  late final HunterProfileRepository _repository;

  @override
  Future<HunterProfileOverview> build() async {
    _repository = ref.watch(hunterProfileRepositoryProvider);
    return _repository.getOverview();
  }

  /// Recarga el perfil completo.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getOverview);
  }
}

final hunterProfileControllerProvider =
    AsyncNotifierProvider<HunterProfileController, HunterProfileOverview>(
      HunterProfileController.new,
    );
