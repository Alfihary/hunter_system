import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../features/health/presentation/providers/health_controller.dart';
import '../../data/app_bootstrap_service.dart';
import '../../domain/app_bootstrap_result.dart';

/// Provider del servicio de bootstrap.
///
/// ¿Qué hace?
/// Inyecta el servicio que prepara el sistema al arranque.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la lógica técnica del startup.
final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return AppBootstrapService(db: db, healthRepository: healthRepository);
});

/// Controlador principal del arranque técnico.
///
/// ¿Qué hace?
/// Ejecuta el bootstrap al construirse y expone su resultado.
///
/// ¿Para qué sirve?
/// Para que la app pueda decidir si ya está lista para navegar.
class AppBootstrapController extends AsyncNotifier<AppBootstrapResult> {
  late final AppBootstrapService _service;

  @override
  Future<AppBootstrapResult> build() async {
    _service = ref.watch(appBootstrapServiceProvider);
    return _service.run();
  }

  /// Reintenta el bootstrap completo.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.run);
  }
}

final appBootstrapControllerProvider =
    AsyncNotifierProvider<AppBootstrapController, AppBootstrapResult>(
      AppBootstrapController.new,
    );
