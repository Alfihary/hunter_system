import 'package:flutter/material.dart';

/// Panel visual reutilizable estilo Hunter System.
///
/// ¿Qué hace?
/// Crea una superficie oscura con borde suave y esquinas redondeadas.
///
/// ¿Para qué sirve?
/// Para evitar repetir el mismo diseño en Home, Entreno, Stats,
/// Historial, Perfil, Hábitos y Nutrición.
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF1D2033) : const Color(0xFF181827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF55C8FF).withOpacity(0.20)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }
}