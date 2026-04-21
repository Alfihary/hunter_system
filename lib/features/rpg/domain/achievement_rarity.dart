/// Rarezas de logros del sistema RPG.
///
/// ¿Qué hace?
/// Clasifica visualmente la importancia del logro.
///
/// ¿Para qué sirve?
/// Para darle peso y jerarquía a los logros desbloqueados.
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  /// Etiqueta amigable para la UI.
  String get label {
    switch (this) {
      case AchievementRarity.common:
        return 'Común';
      case AchievementRarity.rare:
        return 'Raro';
      case AchievementRarity.epic:
        return 'Épico';
      case AchievementRarity.legendary:
        return 'Legendario';
      case AchievementRarity.mythic:
        return 'Mítico';
    }
  }

  /// Orden visual de menor a mayor rareza.
  int get sortOrder {
    switch (this) {
      case AchievementRarity.common:
        return 0;
      case AchievementRarity.rare:
        return 1;
      case AchievementRarity.epic:
        return 2;
      case AchievementRarity.legendary:
        return 3;
      case AchievementRarity.mythic:
        return 4;
    }
  }
}
