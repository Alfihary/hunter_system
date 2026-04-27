import 'package:flutter/material.dart';

/// Presets visuales disponibles para Hunter System.
///
/// ¿Qué hace?
/// Define estilos RPG seleccionables desde Profile.
///
/// ¿Para qué sirve?
/// Para que el usuario no sólo cambie claro/oscuro,
/// sino la identidad visual completa de la app.
enum AppThemePreset {
  soloLeveling,
  diablo,
  immortalPurple,
  hunterClassic,
}

extension AppThemePresetX on AppThemePreset {
  String get label {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return 'Solo Leveling';
      case AppThemePreset.diablo:
        return 'Diablo';
      case AppThemePreset.immortalPurple:
        return 'Immortal Purple';
      case AppThemePreset.hunterClassic:
        return 'Hunter Classic';
    }
  }

  String get description {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return 'Negro profundo, cyan mágico y azul sistema.';
      case AppThemePreset.diablo:
        return 'Rojo demoníaco, dorado antiguo y sombras densas.';
      case AppThemePreset.immortalPurple:
        return 'Morado arcano, azul noche y energía mística.';
      case AppThemePreset.hunterClassic:
        return 'Azul hunter clásico, limpio y tecnológico.';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return const Color(0xFF55C8FF);
      case AppThemePreset.diablo:
        return const Color(0xFFFF4B3E);
      case AppThemePreset.immortalPurple:
        return const Color(0xFFB06CFF);
      case AppThemePreset.hunterClassic:
        return const Color(0xFF3D8BFF);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return const Color(0xFF8C7CFF);
      case AppThemePreset.diablo:
        return const Color(0xFFFFB84D);
      case AppThemePreset.immortalPurple:
        return const Color(0xFF55C8FF);
      case AppThemePreset.hunterClassic:
        return const Color(0xFF55C8FF);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return const Color(0xFF07070D);
      case AppThemePreset.diablo:
        return const Color(0xFF090404);
      case AppThemePreset.immortalPurple:
        return const Color(0xFF080512);
      case AppThemePreset.hunterClassic:
        return const Color(0xFF050912);
    }
  }

  Color get surfaceColor {
    switch (this) {
      case AppThemePreset.soloLeveling:
        return const Color(0xFF171724);
      case AppThemePreset.diablo:
        return const Color(0xFF1A0D0B);
      case AppThemePreset.immortalPurple:
        return const Color(0xFF181025);
      case AppThemePreset.hunterClassic:
        return const Color(0xFF101827);
    }
  }
}