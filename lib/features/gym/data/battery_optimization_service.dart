import 'dart:io';

import 'package:flutter/services.dart';

/// Wraps native MethodChannel calls for battery optimization checks.
class BatteryOptimizationService {
  BatteryOptimizationService._();
  static final instance = BatteryOptimizationService._();

  static const _channel = MethodChannel('com.mujtaba.coresync/step_counter');

  /// Returns true if the app is exempted from battery optimization.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Fires the system dialog to exempt the app from battery optimization.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final ignoring = await isIgnoringBatteryOptimizations();
      if (ignoring) return true;
      return await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens OEM-specific autostart / battery settings. Returns true if opened.
  Future<bool> openOemBatterySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openOemBatterySettings') ?? false;
    } catch (_) {
      return false;
    }
  }
}
