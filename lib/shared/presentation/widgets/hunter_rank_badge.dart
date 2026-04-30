import 'package:flutter/material.dart';

/// Badge visual del rango del cazador.
///
/// ¿Qué hace?
/// Muestra el rango con color temático y apariencia más fuerte.
///
/// ¿Para qué sirve?
/// Para reforzar visualmente el progreso RPG del usuario.
class HunterRankBadge extends StatelessWidget {
  final String rankLabel;
  final bool compact;

  const HunterRankBadge({
    super.key,
    required this.rankLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForRank(rankLabel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Rango $rankLabel',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _colorForRank(String rank) {
    switch (rank.toUpperCase()) {
      case 'E':
        return Colors.grey;
      case 'D':
        return Colors.green;
      case 'C':
        return Colors.lightBlue;
      case 'B':
        return Colors.blue;
      case 'A':
        return Colors.purple;
      case 'S':
        return Colors.orange;
      case 'SS':
        return Colors.deepOrange;
      case 'SSS+':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
