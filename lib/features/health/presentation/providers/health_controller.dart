import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/plugin_health_repository.dart';
import '../../domain/health_overview.dart';
import '../../domain/health_repository.dart';

/// Provider del repositorio Health.
///
/// ¿Qué hace?
/// Inyecta la implementación basada en plugin.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la implementación real.
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return PluginHealthRepository();
});

/// Controlador principal del módulo Health.
///
/// ¿Qué hace?
/// Carga pasos y sueño del día actual.
///
/// ¿Para qué sirve?
/// Para mantener la UI declarativa y limpia.
class HealthController extends AsyncNotifier<HealthOverview> {
  late final HealthRepository _repository;

  @override
  Future<HealthOverview> build() async {
    _repository = ref.watch(healthRepositoryProvider);
    return _repository.getTodayOverview();
  }

  /// Recarga el overview desde la fuente de salud.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getTodayOverview);
  }
}

final healthControllerProvider =
    AsyncNotifierProvider<HealthController, HealthOverview>(
      HealthController.new,
    );

/// Controlador de acciones del módulo Health.
///
/// ¿Qué hace?
/// Ejecuta acciones como pedir permisos.
///
/// ¿Para qué sirve?
/// Para no mezclar acciones mutables con la lectura principal del overview.
class HealthActionController extends AsyncNotifier<void> {
  late final HealthRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(healthRepositoryProvider);
  }

  /// Solicita permisos y refresca el overview si fue posible.
  Future<String?> requestPermissions() async {
    state = const AsyncLoading();

    try {
      final granted = await _repository.requestPermissions();

      ref.invalidate(healthControllerProvider);

      state = const AsyncData(null);

      if (!granted) {
        return 'No se otorgaron los permisos de salud.';
      }

      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }
}

final healthActionControllerProvider =
    AsyncNotifierProvider<HealthActionController, void>(
      HealthActionController.new,
    );
