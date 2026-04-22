import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/daily_steps_summary.dart';
import '../domain/health_overview.dart';
import '../domain/health_repository.dart';
import '../domain/sleep_day_summary.dart';

/// Implementación del módulo Health usando el plugin `health`.
///
/// ¿Qué hace?
/// - solicita permisos
/// - lee pasos del día
/// - lee sueño reciente
///
/// ¿Para qué sirve?
/// Para conectar la app con Apple Health / Health Connect
/// sin meter todavía persistencia local.
class PluginHealthRepository implements HealthRepository {
  static const int _defaultStepsGoal = 8000;
  static const int _defaultSleepGoalMinutes = 7 * 60;

  final Health _health;

  bool _configured = false;

  PluginHealthRepository({Health? health}) : _health = health ?? Health();

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

    /// En Android, pasos requiere Activity Recognition.
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
  ///
  /// Nota:
  /// En iOS antiguo algunos stage types pueden variar.
  /// Esta lista prioriza tipos útiles y comunes para Android/iOS modernos.
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
  ///
  /// ¿Qué hace?
  /// Consulta puntos de sueño y calcula:
  /// - minutos dormidos
  /// - minutos despierto
  /// - minutos deep/rem/light
  /// - cantidad de sesiones detectadas
  ///
  /// ¿Para qué sirve?
  /// Para tener una primera versión simple y útil del módulo de sueño.
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

    /// Rango total de sueño sin doble contar.
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
///
/// ¿Qué hace?
/// Representa un intervalo simple con inicio y fin.
///
/// ¿Para qué sirve?
/// Para fusionar periodos de sueño y evitar doble conteo.
class _TimeRange {
  final DateTime start;
  final DateTime end;

  const _TimeRange(this.start, this.end);
}
