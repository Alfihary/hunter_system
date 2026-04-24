import 'package:flutter/material.dart';

import 'hunter_surface_card.dart';

/// Panel reutilizable de métrica con progreso.
///
/// ¿Qué hace?
/// Muestra:
/// - ícono
/// - título
/// - valor principal
/// - barra de progreso
/// - subtítulo
///
/// ¿Para qué sirve?
/// Para estandarizar visualmente cards de pasos, sueño,
/// misiones, tablero semanal, etc.
class HunterProgressPanel extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final IconData icon;
  final bool highlighted;

  const HunterProgressPanel({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      highlighted: highlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
