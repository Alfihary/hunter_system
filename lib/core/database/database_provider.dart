import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Provider global de la base de datos.
///
/// ¿Qué hace?
/// Crea una única instancia de AppDatabase.
///
/// ¿Para qué sirve?
/// Para que cualquier repositorio pueda usar la base de datos
/// sin crear conexiones manuales en cada pantalla.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(() {
    database.close();
  });

  return database;
});