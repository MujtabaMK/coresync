import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton service that tracks steps using the hardware step counter sensor.
///
/// On Android, a native foreground service (StepCounterForegroundService)
/// counts steps 24/7 using TYPE_STEP_COUNTER and syncs to Firestore every
/// 15 minutes — even when the Flutter app is closed.
/// On iOS, uses CMPedometer.
class StepCounterService {
  StepCounterService._();
  static final instance = StepCounterService._();

  static const _boxName = 'step_counter';
  static const _kDate = 'saved_date';
  static const _kRaw = 'saved_raw';
  static const _kSteps = 'saved_steps';
  static const _channel = MethodChannel('com.mujtaba.coresync/step_counter');

  final _pedometer = Pedometer();
  final _health = Health();
  StreamSubscription<int>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  bool _initialized = false;
  bool _isRefreshing = false;

  // Android periodic polling
  Timer? _androidPollTimer;
  int? _lastPolledNativeSteps;

  // iOS specific
  int _platformBaseline = 0;
  int? _streamBaseline;
  bool _hasPlatformBaseline = false;
  bool _hasHealthKit = false;
  Timer? _healthKitTimer;

  // Cached health metrics (available to all screens via the singleton)
  bool _healthAvailable = false;
  double? _cachedActiveEnergy;
  double? _cachedDistanceKm;

  int _currentSteps = 0;
  PedestrianStatus _currentStatus = PedestrianStatus.unknown;

  /// Stream controller that broadcasts step count changes.
  final _stepsController = StreamController<int>.broadcast();

  /// Stream controller that broadcasts pedestrian status changes.
  final _statusController = StreamController<PedestrianStatus>.broadcast();

  /// Stream controller that fires when cached health metrics (kcal, distance) update.
  final _healthMetricsController = StreamController<void>.broadcast();

  /// Current step count for today.
  int get currentSteps => _currentSteps;

  /// Current pedestrian status.
  PedestrianStatus get currentStatus => _currentStatus;

  /// Whether HealthKit (iOS) or Health Connect (Android) is available.
  bool get isHealthAvailable => _healthAvailable;

  /// Cached active energy (kcal) from HealthKit / Health Connect, or null.
  double? get cachedActiveEnergy => _cachedActiveEnergy;

  /// Cached walking distance (km) from HealthKit / Health Connect, or null.
  double? get cachedDistanceKm => _cachedDistanceKm;

  /// Stream of today's step count updates.
  Stream<int> get stepsStream => _stepsController.stream;

  /// Stream of pedestrian status updates.
  Stream<PedestrianStatus> get statusStream => _statusController.stream;

  /// Stream that fires when health metrics (kcal, distance) are refreshed.
  Stream<void> get healthMetricsStream => _healthMetricsController.stream;

  // ── Native service helpers (Android only) ──

  /// Start the native Android foreground service for background step counting.
  static Future<void> startNativeService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      debugPrint('Failed to start step counter service: $e');
    }
  }

  /// Read today's step count cached by the native foreground service.
  static Future<int> getNativeSteps() async {
    if (!Platform.isAndroid) return 0;
    try {
      return await _channel.invokeMethod<int>('getSteps') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Public API ──

  /// Initialize the step counter. Safe to call multiple times.
  /// Returns false if permission was denied or sensor is unavailable.
  Future<bool> initialize() async {
    if (_initialized) return true;

    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) return false;
    }

    _initialized = true;

    // Check if HealthKit / Health Connect is available and request permissions
    await _initHealthPlatform();

    if (Platform.isAndroid) {
      _isRefreshing = true;

      // Start the native foreground service so steps are tracked 24/7.
      await startNativeService();

      // Use native foreground service for step counting on Android.
      final nativeSteps = await getNativeSteps();
      if (nativeSteps > _currentSteps) {
        _currentSteps = nativeSteps;
        _stepsController.add(_currentSteps);
      }

      // Persist the authoritative step count and clear the stale pedometer
      // raw baseline. Without this, the first pedometer stream event would
      // compute a delta from the old _kRaw and add it on top of the
      // native value, double-counting steps taken before this init.
      final box = await Hive.openBox(_boxName);
      await box.put(_kSteps, _currentSteps);
      await box.put(_kDate, _todayKey());
      await box.delete(_kRaw);
      _isRefreshing = false;
      _lastPolledNativeSteps = null;
    }

    _stepSub = _pedometer.stepCountStream().listen(
      (rawSteps) async {
        if (Platform.isAndroid) {
          await _handleAndroidSensorEvent(rawSteps);
        } else {
          _handleIOSSensorEvent(rawSteps);
        }
      },
      onError: (error) {
        debugPrint('Step count error: $error');
      },
    );

    _statusSub = _pedometer.pedestrianStatusStream().listen(
      (status) {
        _currentStatus = status;
        _statusController.add(status);
      },
      onError: (error) {
        debugPrint('Pedestrian status error: $error');
      },
    );

    // Android: poll native foreground service every 1s for live updates.
    // The pedometer stream can be unreliable on many devices, so this
    // ensures the UI always reflects the latest step count immediately.
    if (Platform.isAndroid) {
      _androidPollTimer?.cancel();
      _androidPollTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _pollNativeSteps(),
      );
    }

    // iOS: get initial baseline from HealthKit (auth already requested above)
    if (Platform.isIOS) {
      await _refreshIOSBaseline();

      // When HealthKit is available, periodically re-sync to stay accurate.
      // This prevents drift from CMPedometer stream deltas that Apple Health
      // would otherwise deduplicate (e.g. iPhone + Apple Watch overlap).
      if (_hasHealthKit) {
        _healthKitTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) {
            _refreshIOSBaseline();
            refreshHealthMetrics();
          },
        );
      }
    }

    // Fetch initial active energy & distance from health platform
    refreshHealthMetrics();

    return true;
  }

  /// Set the initial step count (e.g. from Firestore) so we never go below it.
  /// On Android, also updates the native service baseline so it counts from
  /// this value instead of 0 (fixes steps not incrementing after reinstall).
  void setMinSteps(int steps) {
    if (steps > _currentSteps) {
      _currentSteps = steps;
      _stepsController.add(_currentSteps);

      if (Platform.isAndroid) {
        _channel
            .invokeMethod('setBaseline', {'steps': steps})
            .catchError((_) => null);
      }
    }
  }

  /// Refresh step count and health metrics on app resume.
  Future<void> refreshOnResume() async {
    if (Platform.isIOS) {
      await _refreshIOSBaseline();
    } else if (Platform.isAndroid) {
      await _refreshAndroidOnResume();
    }
    refreshHealthMetrics();
  }

  // ── Android ──

  /// Poll the native foreground service for the latest step count.
  /// Uses delta-based tracking so steps still increment even when native
  /// is below [_currentSteps] (e.g. after reinstall with Firestore baseline).
  Future<void> _pollNativeSteps() async {
    if (_isRefreshing) return;
    final nativeSteps = await getNativeSteps();

    bool changed = false;

    if (nativeSteps > _currentSteps) {
      // Normal case: native has the baseline and is ahead — use it directly.
      _currentSteps = nativeSteps;
      _lastPolledNativeSteps = nativeSteps;
      changed = true;
    } else if (_lastPolledNativeSteps != null &&
        nativeSteps > _lastPolledNativeSteps! &&
        nativeSteps < _currentSteps) {
      // Native increased since last poll but is still below _currentSteps.
      // This happens right after reinstall before the Firestore baseline is
      // applied to native SharedPrefs. Add the delta so the UI still updates.
      // The guard `nativeSteps < _currentSteps` ensures we skip large jumps
      // caused by setBaseline (those are caught by the first branch above).
      final delta = nativeSteps - _lastPolledNativeSteps!;
      _currentSteps += delta;
      _lastPolledNativeSteps = nativeSteps;
      changed = true;
    } else {
      // First poll or no change — just record the native value.
      _lastPolledNativeSteps ??= nativeSteps;
    }

    if (changed) {
      _stepsController.add(_currentSteps);
      final box = await Hive.openBox(_boxName);
      await box.put(_kSteps, _currentSteps);
      await box.put(_kDate, _todayKey());
    }
  }

  Future<void> _refreshAndroidOnResume() async {
    _isRefreshing = true;
    // Use native foreground service for step counting on Android.
    final nativeSteps = await getNativeSteps();
    if (nativeSteps > _currentSteps) {
      _currentSteps = nativeSteps;
      _stepsController.add(_currentSteps);
    }

    // Persist the authoritative step count and clear the stale pedometer
    // raw baseline to prevent double-counting.
    final box = await Hive.openBox(_boxName);
    await box.put(_kSteps, _currentSteps);
    await box.put(_kDate, _todayKey());
    await box.delete(_kRaw);
    _isRefreshing = false;
    _lastPolledNativeSteps = null;

    // Re-subscribe to the sensor stream in case the OS killed it
    _stepSub?.cancel();
    _stepSub = _pedometer.stepCountStream().listen(
      (rawSteps) async => _handleAndroidSensorEvent(rawSteps),
      onError: (error) => debugPrint('Step count error: $error'),
    );
  }

  Future<void> _handleAndroidSensorEvent(int rawSteps) async {
    // Skip events while refreshing to prevent reading stale Hive state
    if (_isRefreshing) return;
    final box = await Hive.openBox(_boxName);
    final todayKey = _todayKey();

    final savedDate = box.get(_kDate) as String?;
    final savedRaw = box.get(_kRaw) as int?;
    final savedSteps = box.get(_kSteps, defaultValue: 0) as int;

    int todaySteps;

    if (savedDate == todayKey && savedRaw != null) {
      if (rawSteps >= savedRaw) {
        final delta = rawSteps - savedRaw;
        todaySteps = savedSteps + delta;
      } else {
        // Device rebooted
        todaySteps = savedSteps + rawSteps;
      }
    } else if (savedDate == todayKey) {
      // Same day but no raw baseline (e.g. after resume cleared _kRaw).
      // Keep existing steps and establish a new raw baseline for future deltas.
      todaySteps = savedSteps;
    } else {
      // New day — use native service
      final nativeSteps = await getNativeSteps();
      todaySteps = nativeSteps;
      // Reset _currentSteps for the new day so max() below doesn't carry
      // yesterday's value forward.
      _currentSteps = 0;
    }

    // Never go below previously known value
    todaySteps = max(todaySteps, _currentSteps);

    // Sanity check: cap at 100k steps/day to prevent raw sensor value leak
    if (todaySteps > 100000) {
      debugPrint('Step count suspiciously high ($todaySteps), capping to previous value');
      todaySteps = _currentSteps;
    }

    await box.put(_kDate, todayKey);
    await box.put(_kRaw, rawSteps);
    await box.put(_kSteps, todaySteps);

    _currentSteps = todaySteps;
    _stepsController.add(_currentSteps);
  }

  /// Calculate active calories burned from steps using MET-based formula.
  /// Matches Apple Health / Google Fit methodology:
  ///   Active kcal = (MET - 1) × weight × time
  /// where time is derived from estimated distance and walking speed.
  static double calculateStepCalories({
    required int steps,
    required double weightKg,
    double? heightCm,
  }) {
    if (steps <= 0) return 0;
    // Stride length from height, default 0.75m
    final strideLengthM = heightCm != null ? heightCm * 0.415 / 100 : 0.75;
    final distanceKm = steps * strideLengthM / 1000;

    const speedKmh = 4.5; // average walking pace
    final timeHours = distanceKm / speedKmh;

    const walkingMET = 3.5;
    // Subtract 1 MET (resting) to get ACTIVE energy only,
    // matching Apple Health's "Active Energy" / Google Fit's active calories.
    return (walkingMET - 1.0) * weightKg * timeHours;
  }

  /// Check if HealthKit (iOS) is available.
  /// Health Connect on Android is disabled — native foreground service handles steps.
  Future<bool> _isHealthPlatformAvailable() async {
    try {
      if (Platform.isIOS) return true; // HealthKit is always on iOS
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Request health permissions and check availability.
  /// Call once at startup; result is cached in [isHealthAvailable].
  /// Only HealthKit on iOS — Health Connect on Android is disabled.
  Future<bool> _initHealthPlatform() async {
    _healthAvailable = await _isHealthPlatformAvailable();
    if (!_healthAvailable) return false;

    try {
      await _health.configure();
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];
      await _health.requestAuthorization(
        types,
        permissions: types.map((_) => HealthDataAccess.READ).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Refresh cached active energy and distance from HealthKit / Health Connect.
  Future<void> refreshHealthMetrics() async {
    if (!_healthAvailable) return;
    _cachedActiveEnergy = await _readActiveEnergy();
    _cachedDistanceKm = await _readWalkingDistanceKm();
    _healthMetricsController.add(null);
  }

  /// Read today's steps from HealthKit (iOS) or Health Connect (Android).
  Future<int?> _getHealthSteps() async {
    if (!_healthAvailable) return null;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      debugPrint('Health getSteps error: $e');
      return null;
    }
  }

  /// Read today's active energy burned (kcal) from HealthKit / Health Connect.
  Future<double?> _readActiveEnergy() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      if (data.isEmpty) return null;
      final unique = _health.removeDuplicates(data);
      double total = 0;
      for (final point in unique) {
        if (point.value is NumericHealthValue) {
          total +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return total > 0 ? total : null;
    } catch (e) {
      debugPrint('Health getActiveEnergy error: $e');
      return null;
    }
  }

  /// Read today's walking/running distance (km) from HealthKit (iOS only).
  Future<double?> _readWalkingDistanceKm() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: midnight,
        endTime: now,
      );
      if (data.isEmpty) return null;
      final unique = _health.removeDuplicates(data);
      double totalMeters = 0;
      for (final point in unique) {
        if (point.value is NumericHealthValue) {
          totalMeters +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return totalMeters > 0 ? totalMeters / 1000 : null;
    } catch (e) {
      debugPrint('Health getDistance error: $e');
      return null;
    }
  }

  // ── iOS ──

  Future<void> _refreshIOSBaseline() async {
    // Prefer HealthKit (matches Apple Health's deduplicated count exactly)
    final healthSteps = await _getHealthSteps();
    if (healthSteps != null && healthSteps > 0) {
      _hasHealthKit = true;
      _hasPlatformBaseline = true;

      if (healthSteps >= _currentSteps) {
        // HealthKit caught up or surpassed the live CMPedometer count.
        // Use it as the new authoritative baseline and reset delta tracking
        // so subsequent stream events compute fresh deltas from here.
        _platformBaseline = healthSteps;
        _streamBaseline = null;
        _currentSteps = healthSteps;
        _stepsController.add(_currentSteps);
      }
      // If healthSteps < _currentSteps, the live CMPedometer count is more
      // recent — keep it. HealthKit will catch up on the next refresh.
      return;
    }

    // Fallback to CMPedometer query if HealthKit is unavailable
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _pedometer.getStepCount(from: midnight, to: now);
      if (steps >= _currentSteps) {
        _platformBaseline = steps;
        _hasPlatformBaseline = true;
        _streamBaseline = null;
        _currentSteps = steps;
        _stepsController.add(_currentSteps);
      }
    } catch (e) {
      debugPrint('CMPedometer getStepCount error: $e');
    }
  }

  void _handleIOSSensorEvent(int rawSteps) {
    // Always use CMPedometer stream for real-time step updates.
    // HealthKit is periodically queried (every 30s) for authoritative
    // correction (e.g. Apple Watch deduplication), but the live stream
    // drives instant per-step updates in the UI.
    _streamBaseline ??= rawSteps;
    final delta = rawSteps - _streamBaseline!;

    final liveCount = _hasPlatformBaseline
        ? _platformBaseline + delta
        : _currentSteps + delta;

    // Never go below previously known value
    if (liveCount > _currentSteps) {
      _currentSteps = liveCount;
      _stepsController.add(_currentSteps);
    }
  }

  // ── Shared ──

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Sync historical steps from Health Connect (Android) or CMPedometer (iOS).
  Future<void> syncHistoricalSteps(Future<void> Function(DateTime, int) saveSteps) async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);

    if (Platform.isIOS) {
      // Prefer HealthKit for historical data (matches Apple Health)
      bool usedHealthKit = false;
      try {
        for (var d = today.subtract(const Duration(days: 1));
            !d.isBefore(firstOfMonth);
            d = d.subtract(const Duration(days: 1))) {
          final dayEnd = d.add(const Duration(days: 1));
          final steps = await _health.getTotalStepsInInterval(d, dayEnd);
          if (steps != null && steps > 0) {
            await saveSteps(d, steps);
          }
        }
        usedHealthKit = true;
      } catch (_) {}

      // Fallback to CMPedometer if HealthKit failed
      if (!usedHealthKit) {
        for (var d = today.subtract(const Duration(days: 1));
            !d.isBefore(firstOfMonth);
            d = d.subtract(const Duration(days: 1))) {
          try {
            final dayEnd = d.add(const Duration(days: 1));
            final steps = await _pedometer.getStepCount(from: d, to: dayEnd);
            if (steps > 0) {
              await saveSteps(d, steps);
            }
          } catch (e) {
            break;
          }
        }
      }
    }
    // Android: historical steps are synced by the native foreground service
    // to Firestore, so no Health Connect query needed here.
  }

  void dispose() {
    _androidPollTimer?.cancel();
    _healthKitTimer?.cancel();
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepsController.close();
    _statusController.close();
    _healthMetricsController.close();
    _initialized = false;
  }
}