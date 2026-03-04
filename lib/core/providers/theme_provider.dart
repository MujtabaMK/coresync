import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../services/hive_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  static const _boxName = 'app_settings';
  static const _key = 'theme_mode';

  Future<void> init() async {
    final box = await HiveService.openBox(_boxName);
    final stored = box.get(_key, defaultValue: 'system') as String;
    emit(_fromString(stored));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final box = await HiveService.openBox(_boxName);
    await box.put(_key, _toString(mode));
    emit(mode);
  }

  Future<void> toggle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  static ThemeMode _fromString(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _toString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
