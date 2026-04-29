import '../../rpg/domain/rpg_stats.dart';

/// Resultado del análisis de atributos RPG.
///
/// ¿Qué hace?
/// Interpreta los stats del usuario.
///
/// ¿Para qué sirve?
/// Para mostrar feedback inteligente tipo videojuego.
class RpgStatsAnalysis {
  final String strongestStat;
  final String weakestStat;
  final bool isBalanced;
  final String title;
  final String message;

  const RpgStatsAnalysis({
    required this.strongestStat,
    required this.weakestStat,
    required this.isBalanced,
    required this.title,
    required this.message,
  });
}

/// Servicio de análisis de stats.
///
/// Mantiene la lógica fuera de UI.
class RpgStatsAnalyzer {
  static RpgStatsAnalysis analyze(RpgStats stats) {
    final map = {
      'Strength': stats.strength,
      'Endurance': stats.endurance,
      'Discipline': stats.discipline,
      'Recovery': stats.recovery,
      'Balance': stats.balance,
      'Consistency': stats.consistency,
    };

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongest = sorted.first;
    final weakest = sorted.last;

    final values = map.values.toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    final difference = max - min;

    final isBalanced = difference <= 10;

    if (isBalanced) {
      return RpgStatsAnalysis(
        strongestStat: strongest.key,
        weakestStat: weakest.key,
        isBalanced: true,
        title: 'Perfil equilibrado',
        message: 'Tus atributos están bien balanceados. Sigue así.',
      );
    }

    return RpgStatsAnalysis(
      strongestStat: strongest.key,
      weakestStat: weakest.key,
      isBalanced: false,
      title: 'Mejora detectada',
      message:
          'Tu punto fuerte es ${strongest.key}, pero necesitas mejorar ${weakest.key}.',
    );
  }
}
