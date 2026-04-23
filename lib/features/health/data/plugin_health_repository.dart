import 'dart:io';

import 'package:drift/drift.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../domain/daily_steps_summary.dart';
import '../domain/health_daily_record.dart';
import '../domain/health_overview.dart';
import '../domain/health_repository.dart';
import '../domain/sleep_day_summary.dart';

/// Implementación del módulo Health usando el plugin `health` + cache local.
///
/// ¿Qué hace?
/// - solicita permisos
/// - lee pasos del día
/// - lee sueño reciente
/// - guarda snapshot diario en Drift
///
/// ¿Para qué sirve?
/// Para que Health funcione como fuente estable del RPG.
class PluginHealthRepository implements HealthRepository {
  static const int _defaultStepsGoal = 8000;
  static const int _defaultSleepGoalMinutes = 7 * 60;

  final Health _health;
  final AppDatabase db;

  bool _configured = false;

  PluginHealthRepository(this.db, {Health? health})
    : _health = health ?? Health();

  @override
  Future<bool> hasPermissions() async {
    if (!_isSupportedPlatform) return false;

    await _ensureConfigured();

    final granted = await _health.hasPermissions(
      _readTypes,
      permissions: _readPermissions,
    );

    return granted ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isSupportedPlatform) return false;

    await _ensureConfigured();

    if (Platform.isAndroid) {
      final activityRecognition = await Permission.activityRecognition
          .request();
      if (!activityRecognition.isGranted) {
        return false;
      }
    }

    final granted = await _health.requestAuthorization(
      _readTypes,
      permissions: _readPermissions,
    );

    return granted;
  }

  @override
  Future<HealthOverview> getTodayOverview() async {
    return _readTodayOverview(persistToCache: true);
  }

  @override
  Future<void> syncTodayToCache() async {
    await _readTodayOverview(persistToCache: true);
  }

  @override
  Future<List<HealthDailyRecord>> getCachedDailyRecords({
    int limitDays = 90,
  }) async {
    final rows =
        await (db.select(db.healthDailySnapshots)
              ..orderBy([(table) => OrderingTerm.desc(table.dateKey)])
              ..limit(limitDays))
            .get();

    return rows
        .map(
          (row) => HealthDailyRecord(
            dateKey: row.dateKey,
            steps: row.steps,
            goalSteps: row.goalSteps,
            totalSleepMinutes: row.totalSleepMinutes,
            goalSleepMinutes: row.goalSleepMinutes,
            awakeMinutes: row.awakeMinutes,
            lightMinutes: row.lightMinutes,
            deepMinutes: row.deepMinutes,
            remMinutes: row.remMinutes,
            sessionCount: row.sessionCount,
            syncedAt: row.syncedAt,
          ),
        )
        .toList();
  }

  /// Lee el overview de hoy y opcionalmente lo guarda en cache.
  Future<HealthOverview> _readTodayOverview({
    required bool persistToCache,
  }) async {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);

    if (!_isSupportedPlatform) {
      return HealthOverview(
        date: normalizedToday,
        isSupportedPlatform: false,
        hasPermissions: false,
        steps: const DailyStepsSummary(steps: 0, goalSteps: _defaultStepsGoal),
        sleep: const SleepDaySummary(
          totalMinutesAsleep: 0,
          awakeMinutes: 0,
          lightMinutes: 0,
          deepMinutes: 0,
          remMinutes: 0,
          sessionCount: 0,
          goalSleepMinutes: _defaultSleepGoalMinutes,
        ),
      );
    }

    await _ensureConfigured();

    final authorized = await hasPermissions();
    if (!authorized) {
      return HealthOverview(
        date: normalizedToday,
        isSupportedPlatform: true,
        hasPermissions: false,
        steps: const DailyStepsSummary(steps: 0, goalSteps: _defaultStepsGoal),
        sleep: const SleepDaySummary(
          totalMinutesAsleep: 0,
          awakeMinutes: 0,
          lightMinutes: 0,
          deepMinutes: 0,
          remMinutes: 0,
          sessionCount: 0,
          goalSleepMinutes: _defaultSleepGoalMinutes,
        ),
      );
    }

    final steps = await _readStepsSummary(now);
    final sleep = await _readRecentSleepSummary(now);

    if (persistToCache) {
      await _upsertDailySnapshot(
        dateKey: _dateKey(normalizedToday),
        steps: steps.steps,
        goalSteps: steps.goalSteps,
        totalSleepMinutes: sleep.totalMinutesAsleep,
        goalSleepMinutes: sleep.goalSleepMinutes,
        awakeMinutes: sleep.awakeMinutes,
        lightMinutes: sleep.lightMinutes,
        deepMinutes: sleep.deepMinutes,
        remMinutes: sleep.remMinutes,
        sessionCount: sleep.sessionCount,
      );
    }

    return HealthOverview(
      date: normalizedToday,
      isSupportedPlatform: true,
      hasPermissions: true,
      steps: steps,
      sleep: sleep,
    );
  }

  /// Indica si la plataforma actual soporta integración de salud.
  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  /// Tipos de lectura necesarios para esta fase.
  List<HealthDataType> get _readTypes => <HealthDataType>[
    HealthDataType.STEPS,
    ..._sleepTypes,
  ];

  /// Permisos de lectura para los tipos usados.
  List<HealthDataAccess> get _readPermissions =>
      List<HealthDataAccess>.filled(_readTypes.length, HealthDataAccess.READ);

  /// Tipos de sueño usados en esta fase.
  List<HealthDataType> get _sleepTypes {
    final types = <HealthDataType>[
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_LIGHT,
    ];

    if (Platform.isAndroid || _isIOS16OrNewer) {
      types.addAll(const [HealthDataType.SLEEP_DEEP, HealthDataType.SLEEP_REM]);
    }

    return types;
  }

  /// Detecta si iOS es 16 o superior.
  bool get _isIOS16OrNewer {
    if (!Platform.isIOS) return false;

    final match = RegExp(r'(\d+)').firstMatch(Platform.operatingSystemVersion);
    final majorVersion = int.tryParse(match?.group(1) ?? '');
    return (majorVersion ?? 0) >= 16;
  }

  /// Configura el plugin una sola vez.
  Future<void> _ensureConfigured() async {
    if (_configured) return;

    await _health.configure();
    _configured = true;
  }

  /// Lee los pasos desde medianoche hasta este momento.
  Future<DailyStepsSummary> _readStepsSummary(DateTime now) async {
    final midnight = DateTime(now.year, now.month, now.day);

    final totalSteps =
        await _health.getTotalStepsInInterval(
          midnight,
          now,
          includeManualEntry: false,
        ) ??
        0;

    return DailyStepsSummary(steps: totalSteps, goalSteps: _defaultStepsGoal);
  }

  /// Lee el sueño reciente dentro de las últimas 24 horas.
  Future<SleepDaySummary> _readRecentSleepSummary(DateTime now) async {
    final startTime = now.subtract(const Duration(hours: 24));

    final points = await _health.getHealthDataFromTypes(
      types: _sleepTypes,
      startTime: startTime,
      endTime: now,
    );

    final uniquePoints = _health.removeDuplicates(points);

    int awakeMinutes = 0;
    int lightMinutes = 0;
    int deepMinutes = 0;
    int remMinutes = 0;

    final asleepRanges = <_TimeRange>[];

    for (final point in uniquePoints) {
      final minutes = _safeMinutes(point.dateFrom, point.dateTo);
      if (minutes <= 0) continue;

      switch (point.type) {
        case HealthDataType.SLEEP_AWAKE:
          awakeMinutes += minutes;
          break;

        case HealthDataType.SLEEP_LIGHT:
          lightMinutes += minutes;
          asleepRanges.add(_TimeRange(point.dateFrom, point.dateTo));
          break;

        case HealthDataType.SLEEP_DEEP:
          deepMinutes += minutes;
          asleepRanges.add(_TimeRange(point.dateFrom, point.dateTo));
          break;

        case HealthDataType.SLEEP_REM:
          remMinutes += minutes;
          asleepRanges.add(_TimeRange(point.dateFrom, point.dateTo));
          break;

        case HealthDataType.SLEEP_ASLEEP:
          asleepRanges.add(_TimeRange(point.dateFrom, point.dateTo));
          break;

        default:
          break;
      }
    }

    final mergedSleepRanges = _mergeRanges(asleepRanges);
    final totalMinutesAsleep = mergedSleepRanges.fold<int>(
      0,
      (sum, range) => sum + _safeMinutes(range.start, range.end),
    );

    return SleepDaySummary(
      totalMinutesAsleep: totalMinutesAsleep,
      awakeMinutes: awakeMinutes,
      lightMinutes: lightMinutes,
      deepMinutes: deepMinutes,
      remMinutes: remMinutes,
      sessionCount: mergedSleepRanges.length,
      goalSleepMinutes: _defaultSleepGoalMinutes,
    );
  }

  /// Inserta o actualiza el snapshot del día actual.
  Future<void> _upsertDailySnapshot({
    required String dateKey,
    required int steps,
    required int goalSteps,
    required int totalSleepMinutes,
    required int goalSleepMinutes,
    required int awakeMinutes,
    required int lightMinutes,
    required int deepMinutes,
    required int remMinutes,
    required int sessionCount,
  }) async {
    await db
        .into(db.healthDailySnapshots)
        .insert(
          HealthDailySnapshotsCompanion.insert(
            dateKey: dateKey,
            steps: Value(steps),
            goalSteps: Value(goalSteps),
            totalSleepMinutes: Value(totalSleepMinutes),
            goalSleepMinutes: Value(goalSleepMinutes),
            awakeMinutes: Value(awakeMinutes),
            lightMinutes: Value(lightMinutes),
            deepMinutes: Value(deepMinutes),
            remMinutes: Value(remMinutes),
            sessionCount: Value(sessionCount),
            syncedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Convierte una fecha a YYYY-MM-DD.
  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  /// Calcula minutos válidos entre dos fechas.
  int _safeMinutes(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return 0;
    return end.difference(start).inMinutes;
  }

  /// Une rangos de tiempo superpuestos para evitar doble conteo.
  List<_TimeRange> _mergeRanges(List<_TimeRange> ranges) {
    if (ranges.isEmpty) return const [];

    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <_TimeRange>[sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final last = merged.last;

      if (!current.start.isAfter(last.end)) {
        final mergedEnd = current.end.isAfter(last.end)
            ? current.end
            : last.end;

        merged[merged.length - 1] = _TimeRange(last.start, mergedEnd);
      } else {
        merged.add(current);
      }
    }

    return merged;
  }
}

/// Rango de tiempo interno.
class _TimeRange {
  final DateTime start;
  final DateTime end;

  const _TimeRange(this.start, this.end);
}
