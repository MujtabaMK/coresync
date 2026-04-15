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
  StreamSubscription<int>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  bool _initialized = false;
  bool _isRefreshing = false;

  // iOS specific
  int _platformBaseline = 0;
  int? _streamBaseline;
  bool _hasPlatformBaseline = false;

  int _currentSteps = 0;
  PedestrianStatus _currentStatus = PedestrianStatus.unknown;

  /// Stream controller that broadcasts step count changes.
  final _stepsController = StreamController<int>.broadcast();

  /// Stream controller that broadcasts pedestrian status changes.
  final _statusController = StreamController<PedestrianStatus>.broadcast();

  /// Current step count for today.
  int get currentSteps => _currentSteps;

  /// Current pedestrian status.
  PedestrianStatus get currentStatus => _currentStatus;

  /// Stream of today's step count updates.
  Stream<int> get stepsStream => _stepsController.stream;

  /// Stream of pedestrian status updates.
  Stream<PedestrianStatus> get statusStream => _statusController.stream;

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

    if (Platform.isAndroid) {
      _isRefreshing = true;
      // Start the native foreground service so steps are tracked 24/7.
      await startNativeService();

      // Read steps already counted by the native service while app was closed.
      final nativeSteps = await getNativeSteps();
      if (nativeSteps > _currentSteps) {
        _currentSteps = nativeSteps;
        _stepsController.add(_currentSteps);
      }

      // Also try Health Connect as a secondary source (if available).
      final hcSteps = await _getHealthConnectSteps();
      if (hcSteps != null && hcSteps > _currentSteps) {
        _currentSteps = hcSteps;
        _stepsController.add(_currentSteps);
      }

      // Persist the authoritative step count and clear the stale pedometer
      // raw baseline. Without this, the first pedometer stream event would
      // compute a delta from the old _kRaw and add it on top of the
      // native/HC value, double-counting steps taken before this init.
      final box = await Hive.openBox(_boxName);
      await box.put(_kSteps, _currentSteps);
      await box.put(_kDate, _todayKey());
      await box.delete(_kRaw);
      _isRefreshing = false;
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

    // iOS: get initial baseline from CMPedometer
    if (Platform.isIOS) {
      await _refreshIOSBaseline();
    }

    return true;
  }

  /// Set the initial step count (e.g. from Firestore) so we never go below it.
  void setMinSteps(int steps) {
    if (steps > _currentSteps) {
      _currentSteps = steps;
      _stepsController.add(_currentSteps);
    }
  }

  /// Refresh step count on app resume.
  Future<void> refreshOnResume() async {
    if (Platform.isIOS) {
      await _refreshIOSBaseline();
    } else if (Platform.isAndroid) {
      await _refreshAndroidOnResume();
    }
  }

  // ── Android ──

  Future<void> _refreshAndroidOnResume() async {
    _isRefreshing = true;
    // 1. Read from native foreground service (primary)
    final nativeSteps = await getNativeSteps();
    if (nativeSteps > _currentSteps) {
      _currentSteps = nativeSteps;
      _stepsController.add(_currentSteps);
    }

    // 2. Also try Health Connect as a secondary source
    final hcSteps = await _getHealthConnectSteps();
    if (hcSteps != null && hcSteps > _currentSteps) {
      _currentSteps = hcSteps;
      _stepsController.add(_currentSteps);
    }

    // 3. Persist the authoritative step count and clear the stale pedometer
    //    raw baseline to prevent double-counting. Without this, the next
    //    pedometer event would compute a delta from the old _kRaw (set
    //    before the app went to background) and add it on top of the
    //    native/HC value — counting background steps twice.
    final box = await Hive.openBox(_boxName);
    await box.put(_kSteps, _currentSteps);
    await box.put(_kDate, _todayKey());
    await box.delete(_kRaw);
    _isRefreshing = false;

    // 4. Re-subscribe to the sensor stream in case the OS killed it
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
    } else {
      // New day — always read native service + Health Connect to bootstrap
      final nativeSteps = await getNativeSteps();
      final hcSteps = await _getHealthConnectSteps();
      todaySteps = max(nativeSteps, max(hcSteps ?? 0, 0));
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

  Future<int?> _getHealthConnectSteps() async {
    if (!Platform.isAndroid) return null;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final health = Health();
      await health.configure();
      return await health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      debugPrint('Health Connect getSteps error: $e');
      return null;
    }
  }

  // ── iOS ──

  Future<void> _refreshIOSBaseline() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _pedometer.getStepCount(from: midnight, to: now);
      _platformBaseline = steps;
      _hasPlatformBaseline = true;
      _streamBaseline = null;
      _currentSteps = _platformBaseline;
      _stepsController.add(_currentSteps);
    } catch (e) {
      debugPrint('CMPedometer getStepCount error: $e');
    }
  }

  void _handleIOSSensorEvent(int rawSteps) {
    _streamBaseline ??= rawSteps;
    final delta = rawSteps - _streamBaseline!;

    final totalToday = _hasPlatformBaseline
        ? _platformBaseline + delta
        : _currentSteps + delta;

    _currentSteps = totalToday;
    _stepsController.add(_currentSteps);
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
    } else if (Platform.isAndroid) {
      try {
        final health = Health();
        await health.configure();
        for (var d = today.subtract(const Duration(days: 1));
            !d.isBefore(firstOfMonth);
            d = d.subtract(const Duration(days: 1))) {
          final dayEnd = d.add(const Duration(days: 1));
          final steps = await health.getTotalStepsInInterval(d, dayEnd);
          if (steps != null && steps > 0) {
            await saveSteps(d, steps);
          }
        }
      } catch (e) {
        debugPrint('Historical sync error: $e');
      }
    }
  }

  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepsController.close();
    _statusController.close();
    _initialized = false;
  }
}