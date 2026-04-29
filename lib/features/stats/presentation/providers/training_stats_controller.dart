import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/training_stats_repository.dart';
import '../../domain/weekly_training_volume.dart';

/// Provider del repositorio de estadísticas.
final trainingStatsRepositoryProvider = Provider<TrainingStatsRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return TrainingStatsRepository(db);
});

/// Provider de volumen semanal de entrenamiento.
final weeklyTrainingVolumeProvider = FutureProvider<List<WeeklyTrainingVolume>>(
  (ref) {
    final repository = ref.watch(trainingStatsRepositoryProvider);
    return repository.getWeeklyTrainingVolume();
  },
);

/// Provider de análisis automático del volumen semanal.
final weeklyTrainingVolumeAnalysisProvider =
    FutureProvider<WeeklyTrainingVolumeAnalysis>((ref) {
      final repository = ref.watch(trainingStatsRepositoryProvider);
      return repository.getWeeklyVolumeAnalysis();
    });
