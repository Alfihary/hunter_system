import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../data/system_diagnostics_repository.dart';
import '../../domain/system_diagnostics_overview.dart';

/// Provider del repositorio de diagnóstico.
///
/// ¿Qué hace?
/// Inyecta la capa que analiza el estado real del sistema.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la lógica de auditoría.
final systemDiagnosticsRepositoryProvider =
    Provider<SystemDiagnosticsRepository>((ref) {
      final db = ref.watch(appDatabaseProvider);
      final healthRepository = ref.watch(healthRepositoryProvider);

      return SystemDiagnosticsRepository(
        db: db,
        healthRepository: healthRepository,
      );
    });

/// Provider principal del overview de diagnóstico.
///
/// ¿Qué hace?
/// Genera un snapshot del estado actual del proyecto.
///
/// ¿Para qué sirve?
/// Para alimentar la pantalla de auditoría.
final systemDiagnosticsOverviewProvider =
    FutureProvider<SystemDiagnosticsOverview>((ref) {
      final repository = ref.watch(systemDiagnosticsRepositoryProvider);
      return repository.getOverview();
    });
