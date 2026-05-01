import 'rpg_text_key.dart';

/// Catálogo local de textos RPG.
///
/// ¿Qué hace?
/// Convierte keys internas en texto visible.
///
/// ¿Para qué sirve?
/// Para no hardcodear textos importantes dentro del repositorio RPG.
class RpgTextCatalog {
  static const Map<String, String> _values = {
    RpgTextKey.achievementConstantIron: 'Constancia de Hierro',
    RpgTextKey.achievementFirstStep: 'Primer Paso',
    RpgTextKey.achievementAscendingStride: 'Zancada Ascendente',

    RpgTextKey.titleThresholdBearer: 'Portador del Umbral',
    RpgTextKey.titleSovereigntyOfHunt: 'Soberanía de Cacería',
  };

  static String get(String key) {
    return _values[key] ?? key;
  }
}
