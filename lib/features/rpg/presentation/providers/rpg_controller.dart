import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/derived_rpg_repository.dart';
import '../../domain/achievement.dart';
import '../../domain/rpg_overview.dart';
import '../../domain/rpg_repository.dart';
import '../../domain/rpg_title.dart';

/// Provider del repositorio RPG.
///
/// ¿Qué hace?
/// Inyecta la implementación derivada desde la base local.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI del cálculo real del sistema RPG.
final rpgRepositoryProvider = Provider<RpgRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DerivedRpgRepository(db);
});

/// Controlador principal del overview RPG.
///
/// ¿Qué hace?
/// Carga el estado completo del personaje.
///
/// ¿Para qué sirve?
/// Para que la UI sea declarativa y no implemente reglas del RPG.
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
///
/// ¿Qué hace?
/// Carga los logros calculados del personaje.
///
/// ¿Para qué sirve?
/// Para alimentar la pantalla de logros.
final rpgAchievementsProvider = FutureProvider<List<Achievement>>((ref) {
  final repository = ref.watch(rpgRepositoryProvider);
  return repository.getAchievements();
});

/// Provider de títulos RPG.
///
/// ¿Qué hace?
/// Carga los títulos, su estado desbloqueado y el título equipado.
///
/// ¿Para qué sirve?
/// Para alimentar la pantalla de títulos.
final rpgTitlesProvider = FutureProvider<List<RpgTitle>>((ref) {
  final repository = ref.watch(rpgRepositoryProvider);
  return repository.getTitles();
});

/// Controlador de acciones RPG.
///
/// ¿Qué hace?
/// Ejecuta acciones como equipar un título.
///
/// ¿Para qué sirve?
/// Para separar acciones mutables de la UI.
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
