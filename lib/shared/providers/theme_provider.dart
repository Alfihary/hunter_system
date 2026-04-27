import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme_preset.dart';

/// Estado global de apariencia.
///
/// ¿Qué hace?
/// Guarda:
/// - modo claro/oscuro
/// - preset visual RPG seleccionado
///
/// ¿Para qué sirve?
/// Para controlar la identidad visual de toda la app desde Profile.
class AppThemeState {
  final ThemeMode mode;
  final AppThemePreset preset;

  const AppThemeState({
    required this.mode,
    required this.preset,
  });

  bool get isDarkMode => mode == ThemeMode.dark;

  AppThemeState copyWith({
    ThemeMode? mode,
    AppThemePreset? preset,
  }) {
    return AppThemeState(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
    );
  }
}

/// Controlador global del tema visual.
class ThemeController extends Notifier<AppThemeState> {
  @override
  AppThemeState build() {
    return const AppThemeState(
      mode: ThemeMode.dark,
      preset: AppThemePreset.soloLeveling,
    );
  }

  void toggleThemeMode() {
    state = state.copyWith(
      mode: state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setPreset(AppThemePreset preset) {
    state = state.copyWith(preset: preset);
  }
}

final themeProvider =
    NotifierProvider<ThemeController, AppThemeState>(ThemeController.new);

/// Compatibilidad temporal con código existente.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).mode;
});