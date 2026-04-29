import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme_preset.dart';

/// Estado global de apariencia.
///
/// ¿Qué hace?
/// Guarda:
/// - modo claro/oscuro
/// - preset visual RPG seleccionado
/// - estado de carga inicial
///
/// ¿Para qué sirve?
/// Para controlar la identidad visual de toda la app desde Profile
/// y recordar la selección aunque la app se cierre.
class AppThemeState {
  final ThemeMode mode;
  final AppThemePreset preset;
  final bool isLoaded;

  const AppThemeState({
    required this.mode,
    required this.preset,
    this.isLoaded = false,
  });

  /// Indica si el modo activo es oscuro.
  bool get isDarkMode => mode == ThemeMode.dark;

  /// Crea una copia segura del estado actual.
  AppThemeState copyWith({
    ThemeMode? mode,
    AppThemePreset? preset,
    bool? isLoaded,
  }) {
    return AppThemeState(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Controlador global del tema visual.
///
/// ¿Qué hace?
/// - Carga configuración guardada.
/// - Cambia modo claro/oscuro.
/// - Cambia preset RPG.
/// - Persiste cada cambio en almacenamiento local.
///
/// ¿Para qué sirve?
/// Para que el Profile sea un centro real de configuración visual.
class ThemeController extends Notifier<AppThemeState> {
  static const String _modeKey = 'hunter_theme_mode';
  static const String _presetKey = 'hunter_theme_preset';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  AppThemeState build() {
    Future.microtask(_loadSavedTheme);

    return const AppThemeState(
      mode: ThemeMode.dark,
      preset: AppThemePreset.soloLeveling,
      isLoaded: false,
    );
  }

  /// Carga el tema guardado en el dispositivo.
  ///
  /// Edge cases cubiertos:
  /// - Si no hay nada guardado, usa dark + Solo Leveling.
  /// - Si el valor guardado ya no existe, regresa al default.
  /// - Si ocurre un error leyendo preferencias, no rompe la app.
  Future<void> _loadSavedTheme() async {
    try {
      final savedMode = await _preferences.getString(_modeKey);
      final savedPreset = await _preferences.getString(_presetKey);

      state = state.copyWith(
        mode: _themeModeFromName(savedMode),
        preset: _presetFromName(savedPreset),
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  /// Alterna entre modo oscuro y claro.
  Future<void> toggleThemeMode() async {
    final nextMode = state.mode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    state = state.copyWith(mode: nextMode);

    await _preferences.setString(_modeKey, nextMode.name);
  }

  /// Selecciona y guarda un preset visual RPG.
  Future<void> setPreset(AppThemePreset preset) async {
    state = state.copyWith(preset: preset);

    await _preferences.setString(_presetKey, preset.name);
  }

  /// Convierte un String guardado a ThemeMode.
  ThemeMode _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }

    return ThemeMode.dark;
  }

  /// Convierte un String guardado a AppThemePreset.
  AppThemePreset _presetFromName(String? name) {
    for (final preset in AppThemePreset.values) {
      if (preset.name == name) return preset;
    }

    return AppThemePreset.soloLeveling;
  }
}

final themeProvider = NotifierProvider<ThemeController, AppThemeState>(
  ThemeController.new,
);

/// Compatibilidad temporal con código existente.
///
/// ¿Qué hace?
/// Expone sólo ThemeMode para pantallas antiguas que todavía lean
/// `themeModeProvider`.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).mode;
});
