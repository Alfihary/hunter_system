/// Rangos globales del personaje.
///
/// ¿Qué hace?
/// Define la clasificación principal del usuario dentro del sistema RPG.
///
/// ¿Para qué sirve?
/// Para mostrar un progreso más épico y fácil de entender que sólo el nivel.
///
/// Regla:
/// Cada rango se desbloquea al llegar a cierto XP total.
enum RpgRank {
  e,
  d,
  c,
  b,
  a,
  s,
  ss,
  sssPlus;

  /// Etiqueta visible para la UI.
  String get label {
    switch (this) {
      case RpgRank.e:
        return 'E';
      case RpgRank.d:
        return 'D';
      case RpgRank.c:
        return 'C';
      case RpgRank.b:
        return 'B';
      case RpgRank.a:
        return 'A';
      case RpgRank.s:
        return 'S';
      case RpgRank.ss:
        return 'SS';
      case RpgRank.sssPlus:
        return 'SSS+';
    }
  }

  /// XP mínimo requerido para pertenecer a este rango.
  int get minimumXp {
    switch (this) {
      case RpgRank.e:
        return 0;
      case RpgRank.d:
        return 300;
      case RpgRank.c:
        return 900;
      case RpgRank.b:
        return 1800;
      case RpgRank.a:
        return 3200;
      case RpgRank.s:
        return 5200;
      case RpgRank.ss:
        return 8000;
      case RpgRank.sssPlus:
        return 12000;
    }
  }

  /// Lista ordenada de menor a mayor rango.
  static List<RpgRank> get ordered => const [
    RpgRank.e,
    RpgRank.d,
    RpgRank.c,
    RpgRank.b,
    RpgRank.a,
    RpgRank.s,
    RpgRank.ss,
    RpgRank.sssPlus,
  ];

  /// Obtiene el rango actual a partir del XP total.
  static RpgRank fromTotalXp(int totalXp) {
    RpgRank current = RpgRank.e;

    for (final rank in ordered) {
      if (totalXp >= rank.minimumXp) {
        current = rank;
      } else {
        break;
      }
    }

    return current;
  }

  /// Obtiene el siguiente rango, si existe.
  RpgRank? get nextRank {
    final index = ordered.indexOf(this);
    if (index < 0 || index == ordered.length - 1) return null;
    return ordered[index + 1];
  }
}
