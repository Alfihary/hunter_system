import 'achievement.dart';
import 'rpg_overview.dart';
import 'rpg_title.dart';

/// Contrato del módulo RPG.
///
/// ¿Qué hace?
/// Define las operaciones principales del sistema RPG.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI del cálculo y persistencia real.
abstract class RpgRepository {
  Future<RpgOverview> getOverview();

  /// Obtiene la lista de logros calculados desde la actividad real.
  Future<List<Achievement>> getAchievements();

  /// Obtiene la lista de títulos desbloqueados y su estado de equipado.
  Future<List<RpgTitle>> getTitles();

  /// Equipa un título desbloqueado.
  Future<void> equipTitle(String titleId);
}
