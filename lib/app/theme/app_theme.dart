import 'package:flutter/material.dart';

import 'app_theme_preset.dart';

/// Tema visual global de Hunter System.
///
/// ¿Qué hace?
/// Construye temas dinámicos según el preset RPG seleccionado:
/// - Solo Leveling
/// - Diablo
/// - Immortal Purple
/// - Hunter Classic
///
/// ¿Para qué sirve?
/// Para que toda la app cambie identidad visual desde Profile
/// sin modificar cada pantalla individualmente.
class AppTheme {
  static const Color _gold = Color(0xFFFFD93D);
  static const Color _danger = Color(0xFFFF5A66);

  /// Tema oscuro dinámico.
  static ThemeData darkTheme(AppThemePreset preset) {
    return _buildTheme(
      preset: preset,
      brightness: Brightness.dark,
      background: preset.backgroundColor,
      surface: preset.surfaceColor,
      textPrimary: Colors.white,
      textSecondary: const Color(0xFFB8B8D8),
    );
  }

  /// Tema claro dinámico.
  ///
  /// Nota:
  /// Aunque sea claro, conserva identidad RPG.
  /// No usamos blanco puro para evitar romper el estilo visual.
  static ThemeData lightTheme(AppThemePreset preset) {
    return _buildTheme(
      preset: preset,
      brightness: Brightness.light,
      background: const Color(0xFFF4F6FB),
      surface: Colors.white,
      textPrimary: const Color(0xFF111827),
      textSecondary: const Color(0xFF5B6475),
    );
  }

  /// Constructor base compartido.
  ///
  /// ¿Por qué existe?
  /// Para no duplicar configuración entre tema claro y oscuro.
  static ThemeData _buildTheme({
    required AppThemePreset preset,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final primary = preset.primaryColor;
    final secondary = preset.secondaryColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      tertiary: _gold,
      error: _danger,
      surface: surface,
      surfaceContainerHighest:
          brightness == Brightness.dark ? surface.withOpacity(0.92) : const Color(0xFFE9ECF5),
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: isDark ? surface.withOpacity(0.92) : Colors.white,
        indicatorColor: primary.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
            color: selected
                ? primary
                : isDark
                    ? const Color(0xFF666681)
                    : const Color(0xFF7A8294),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            size: selected ? 28 : 25,
            color: selected
                ? primary
                : isDark
                    ? const Color(0xFF666681)
                    : const Color(0xFF7A8294),
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF061018) : Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.75)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.35);
          }
          return null;
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF10101A) : const Color(0xFFF0F3FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        labelStyle: TextStyle(color: textSecondary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor:
            isDark ? const Color(0xFF0C0C14) : const Color(0xFFE1E6F0),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 2.6,
          color: secondary,
        ),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? preset.surfaceColor : const Color(0xFF111827),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}