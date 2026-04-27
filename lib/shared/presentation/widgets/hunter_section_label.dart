import 'package:flutter/material.dart';

/// Etiqueta de sección estilo Hunter System.
///
/// ¿Qué hace?
/// Renderiza títulos pequeños en mayúsculas con el estilo global.
///
/// ¿Para qué sirve?
/// Para mantener consistencia visual en secciones como:
/// - MISIÓN DE HOY
/// - PROGRESO DE RANGO
/// - ESTADÍSTICAS RÁPIDAS
class HunterSectionLabel extends StatelessWidget {
  final String text;

  const HunterSectionLabel(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}