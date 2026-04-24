import 'package:flutter/material.dart';

/// Título visual reutilizable para secciones.
///
/// ¿Qué hace?
/// Presenta un encabezado simple con mejor jerarquía visual.
///
/// ¿Para qué sirve?
/// Para que las pantallas largas se lean mejor.
class HunterSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const HunterSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
