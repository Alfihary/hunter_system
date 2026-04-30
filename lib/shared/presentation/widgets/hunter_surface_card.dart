import 'package:flutter/material.dart';

/// Card visual premium del sistema Hunter.
///
/// ¿Qué hace?
/// Envuelve contenido dentro de una superficie adaptable al tema:
/// - dark mode: superficie oscura legible
/// - light mode: superficie clara legible
/// - highlighted: usa el color primario del preset
///
/// ¿Para qué sirve?
/// Para reutilizar una estética consistente sin romper contraste.
class HunterSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const HunterSurfaceCard({
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
        ? scheme.primaryContainer.withValues(alpha: isDark ? 0.42 : 0.75)
        : scheme.surface;

    final borderColor = highlighted
        ? scheme.primary.withValues(alpha: isDark ? 0.38 : 0.28)
        : scheme.outline.withValues(alpha: isDark ? 0.20 : 0.14);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
