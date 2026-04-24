import 'package:flutter/material.dart';

/// Tema visual global de Hunter System.
///
/// ¿Qué hace?
/// Define el estilo principal de la app:
/// - dark mode tipo RPG
/// - fondo negro profundo
/// - cards azul/morado oscuro
/// - acento cyan
/// - XP dorado
/// - navegación inferior estilo móvil RPG
///
/// ¿Para qué sirve?
/// Para que todas las pantallas compartan una identidad visual consistente.
class AppTheme {
  static const Color _darkBackground = Color(0xFF07070D);
  static const Color _darkSurface = Color(0xFF171724);
  static const Color _darkSurfaceVariant = Color(0xFF1E1E2F);
  static const Color _cyan = Color(0xFF55C8FF);
  static const Color _purple = Color(0xFF8C7CFF);
  static const Color _gold = Color(0xFFFFD93D);
  static const Color _danger = Color(0xFFFF5A66);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _cyan,
      brightness: Brightness.dark,
      primary: _cyan,
      secondary: _purple,
      tertiary: _gold,
      error: _danger,
      surface: _darkSurface,
      surfaceContainerHighest: _darkSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: const Color(0xFF11111A),
        indicatorColor: _cyan.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
            color: selected ? _cyan : const Color(0xFF555577),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            size: selected ? 28 : 25,
            color: selected ? _cyan : const Color(0xFF555577),
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: const Color(0xFF061018),
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
          foregroundColor: _cyan,
          side: BorderSide(color: _cyan.withOpacity(0.75)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF10101A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _cyan, width: 1.4),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9B9BC8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _cyan,
        linearTrackColor: Color(0xFF0C0C14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w800),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 2.6,
          color: Color(0xFF9696D6),
        ),
        bodyMedium: TextStyle(color: Color(0xFFE8E8F5)),
        bodySmall: TextStyle(color: Color(0xFF9C9CBF)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceVariant,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    return darkTheme;
  }
}
