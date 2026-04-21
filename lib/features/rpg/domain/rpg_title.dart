/// Título desbloqueable del personaje.
///
/// ¿Qué hace?
/// Representa un título que el usuario puede desbloquear y equipar.
///
/// ¿Para qué sirve?
/// Para darle identidad visual y temática al personaje.
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
}
