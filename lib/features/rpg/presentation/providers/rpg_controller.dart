import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../data/derived_rpg_repository.dart';
import '../../domain/achievement.dart';
import '../../domain/rpg_overview.dart';
import '../../domain/rpg_repository.dart';
import '../../domain/rpg_title.dart';

/// Provider del repositorio RPG.
///
/// ¿Qué hace?
/// Inyecta la implementación derivada desde la base local
/// y la integra con Health.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI del cálculo real del sistema RPG.
final rpgRepositoryProvider = Provider<RpgRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final healthRepository = ref.watch(healthRepositoryProvider);

  return DerivedRpgRepository(db, healthRepository: healthRepository);
});

/// Controlador principal del overview RPG.
class RpgController extends AsyncNotifier<RpgOverview> {
  late final RpgRepository _repository;

  @override
  Future<RpgOverview> build() async {
    _repository = ref.watch(rpgRepositoryProvider);
    return _repository.getOverview();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getOverview);
  }
}

final rpgControllerProvider = AsyncNotifierProvider<RpgController, RpgOverview>(
  RpgController.new,
);

/// Provider de logros RPG.
final rpgAchievementsProvider = FutureProvider<List<Achievement>>((ref) {
  final repository = ref.watch(rpgRepositoryProvider);
  return repository.getAchievements();
});

/// Provider de títulos RPG.
final rpgTitlesProvider = FutureProvider<List<RpgTitle>>((ref) {
  final repository = ref.watch(rpgRepositoryProvider);
  return repository.getTitles();
});

/// Controlador de acciones RPG.
class RpgActionController extends AsyncNotifier<void> {
  late final RpgRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(rpgRepositoryProvider);
  }

  /// Equipa un título desbloqueado y refresca el estado relacionado.
  Future<String?> equipTitle(String titleId) async {
    state = const AsyncLoading();

    try {
      await _repository.equipTitle(titleId);

      ref.invalidate(rpgTitlesProvider);
      ref.invalidate(rpgAchievementsProvider);
      await ref.read(rpgControllerProvider.notifier).reload();

      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }
}

final rpgActionControllerProvider =
    AsyncNotifierProvider<RpgActionController, void>(RpgActionController.new);
