import 'package:flutter/material.dart';

/// Card visual premium del sistema Hunter.
///
/// ¿Qué hace?
/// Envuelve contenido dentro de una superficie más cuidada:
/// - borde suave
/// - sombra ligera
/// - fondo con más presencia
///
/// ¿Para qué sirve?
/// Para reutilizar una estética consistente en Home, Perfil y RPG.
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
    final colorScheme = theme.colorScheme;

    final backgroundColor = highlighted
        ? colorScheme.primaryContainer.withOpacity(0.45)
        : colorScheme.surfaceVariant.withOpacity(0.35);

    final borderColor = highlighted
        ? colorScheme.primary.withOpacity(0.35)
        : colorScheme.outline.withOpacity(0.20);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
