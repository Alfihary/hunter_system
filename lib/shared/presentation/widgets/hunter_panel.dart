import 'package:flutter/material.dart';

/// Panel visual reutilizable estilo Hunter System.
///
/// ¿Qué hace?
/// Crea una superficie adaptable al tema actual:
/// - en modo oscuro usa superficies oscuras
/// - en modo claro usa superficies claras
/// - respeta el preset visual seleccionado
///
/// ¿Para qué sirve?
/// Para evitar texto oscuro sobre cards oscuras cuando el usuario cambia
/// a modo claro.
class HunterPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const HunterPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = highlighted
        ? scheme.primaryContainer.withOpacity(isDark ? 0.38 : 0.70)
        : scheme.surface;

    final borderColor = highlighted
        ? scheme.primary.withOpacity(isDark ? 0.35 : 0.25)
        : scheme.outline.withOpacity(isDark ? 0.18 : 0.14);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
