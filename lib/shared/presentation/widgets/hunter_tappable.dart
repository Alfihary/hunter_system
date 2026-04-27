import 'package:flutter/material.dart';

/// Wrapper táctil reutilizable.
///
/// ¿Qué hace?
/// Hace que cualquier widget sea presionable con efecto InkWell.
///
/// ¿Para qué sirve?
/// Para convertir panels/cards en accesos navegables sin duplicar código.
class HunterTappable extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  const HunterTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: child,
      ),
    );
  }
}