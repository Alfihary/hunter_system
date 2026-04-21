import 'rpg_rank.dart';
import 'rpg_source_breakdown.dart';
import 'rpg_stats.dart';

/// Vista principal del sistema RPG.
///
/// ¿Qué hace?
/// Agrupa toda la información necesaria para la pantalla RPG:
/// - nivel
/// - XP
/// - progreso al siguiente nivel
/// - rango
/// - progreso al siguiente rango
/// - racha global
/// - stats
/// - desglose por fuentes
///
/// ¿Para qué sirve?
/// Para que la UI reciba un solo modelo listo para pintar.
class RpgOverview {
  final int level;
  final int totalXp;
  final int xpIntoCurrentLevel;
  final int xpForNextLevel;

  final RpgRank rank;
  final int xpIntoCurrentRank;
  final int xpForNextRank;
  final RpgRank? nextRank;

  final int activeStreakDays;
  final RpgStats stats;
  final RpgSourceBreakdown breakdown;

  const RpgOverview({
    required this.level,
    required this.totalXp,
    required this.xpIntoCurrentLevel,
    required this.xpForNextLevel,
    required this.rank,
    required this.xpIntoCurrentRank,
    required this.xpForNextRank,
    required this.nextRank,
    required this.activeStreakDays,
    required this.stats,
    required this.breakdown,
  });

  /// Progreso normalizado hacia el siguiente nivel.
  double get levelProgress {
    if (xpForNextLevel <= 0) return 0;
    return (xpIntoCurrentLevel / xpForNextLevel).clamp(0, 1);
  }

  /// Progreso normalizado hacia el siguiente rango.
  double get rankProgress {
    if (xpForNextRank <= 0) return 1;
    return (xpIntoCurrentRank / xpForNextRank).clamp(0, 1);
  }
}
