/// Título desbloqueable del sistema RPG.
///
/// ¿Qué hace?
/// Representa una identidad que el usuario puede desbloquear y equipar.
///
/// ¿Para qué sirve?
/// Para reforzar la sensación de progreso tipo RPG sin depender del género
/// del usuario. Por eso los títulos deben ser neutros.
class RpgTitle {
  final String id;
  final String name;
  final String description;
  final String requirementText;
  final bool isUnlocked;
  final bool isEquipped;
  final int sortOrder;

  const RpgTitle({
    required this.id,
    required this.name,
    required this.description,
    required this.requirementText,
    required this.isUnlocked,
    required this.isEquipped,
    required this.sortOrder,
  });

  /// Indica si el título se puede equipar.
  bool get canEquip => isUnlocked && !isEquipped;

  /// Texto visual de estado.
  String get statusLabel {
    if (isEquipped) return 'Equipado';
    if (isUnlocked) return 'Desbloqueado';
    return 'Bloqueado';
  }
}
