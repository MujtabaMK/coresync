import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/notification_ids.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/gym_provider.dart';

class _MealSlot {
  final String key;
  final String label;
  final int defaultHour;
  final int defaultMinute;
  final int notificationId;

  const _MealSlot({
    required this.key,
    required this.label,
    required this.defaultHour,
    required this.defaultMinute,
    required this.notificationId,
  });
}

const _mealSlots = [
  _MealSlot(key: 'breakfast', label: 'Breakfast', defaultHour: 9, defaultMinute: 0, notificationId: NotificationIds.mealBreakfast),
  _MealSlot(key: 'morning_snack', label: 'Morning Snack', defaultHour: 11, defaultMinute: 0, notificationId: NotificationIds.mealMorningSnack),
  _MealSlot(key: 'lunch', label: 'Lunch', defaultHour: 13, defaultMinute: 0, notificationId: NotificationIds.mealLunch),
  _MealSlot(key: 'evening_snack', label: 'Evening Snack', defaultHour: 17, defaultMinute: 0, notificationId: NotificationIds.mealEveningSnack),
  _MealSlot(key: 'dinner', label: 'Dinner', defaultHour: 20, defaultMinute: 0, notificationId: NotificationIds.mealDinner),
];

class MealReminderScreen extends StatefulWidget {
  const MealReminderScreen({super.key});

  @override
  State<MealReminderScreen> createState() => _MealReminderScreenState();
}

class _MealReminderScreenState extends State<MealReminderScreen> {
  static const _prefix = 'reminder_food';
  bool _masterEnabled = false;
  bool _onceAtEnabled = false;
  int _onceAtHour = 21;
  int _onceAtMinute = 30;
  final Map<String, bool> _mealEnabled = {};
  final Map<String, int> _mealHour = {};
  final Map<String, int> _mealMinute = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await context.read<GymCubit>().repository.getGymSettingsBox();
    setState(() {
      _masterEnabled = box.get('${_prefix}_enabled', defaultValue: false) as bool;
      _onceAtEnabled = box.get('${_prefix}_once_enabled', defaultValue: false) as bool;
      _onceAtHour = box.get('${_prefix}_once_hour', defaultValue: 21) as int;
      _onceAtMinute = box.get('${_prefix}_once_minute', defaultValue: 30) as int;
      for (final slot in _mealSlots) {
        _mealEnabled[slot.key] = box.get('${_prefix}_${slot.key}_enabled', defaultValue: false) as bool;
        _mealHour[slot.key] = box.get('${_prefix}_${slot.key}_hour', defaultValue: slot.defaultHour) as int;
        _mealMinute[slot.key] = box.get('${_prefix}_${slot.key}_minute', defaultValue: slot.defaultMinute) as int;
      }
      _loaded = true;
    });
  }

  Future<void> _saveAndSchedule() async {
    final box = await context.read<GymCubit>().repository.getGymSettingsBox();
    await box.put('${_prefix}_enabled', _masterEnabled);
    await box.put('${_prefix}_once_enabled', _onceAtEnabled);
    await box.put('${_prefix}_once_hour', _onceAtHour);
    await box.put('${_prefix}_once_minute', _onceAtMinute);
    for (final slot in _mealSlots) {
      await box.put('${_prefix}_${slot.key}_enabled', _mealEnabled[slot.key] ?? false);
      await box.put('${_prefix}_${slot.key}_hour', _mealHour[slot.key] ?? slot.defaultHour);
      await box.put('${_prefix}_${slot.key}_minute', _mealMinute[slot.key] ?? slot.defaultMinute);
    }

    // Cancel all meal notifications first
    await NotificationService.cancel(NotificationIds.mealBreakfast - 1); // once-at ID
    for (final slot in _mealSlots) {
      await NotificationService.cancel(slot.notificationId);
    }

    if (!_masterEnabled) return;

    await NotificationService.requestPermissions();

    // Schedule once-at reminder
    if (_onceAtEnabled) {
      await NotificationService.scheduleDailyNotification(
        id: NotificationIds.mealBreakfast - 1,
        title: 'Meal Reminder',
        body: 'Time to track your meals!',
        hour: _onceAtHour,
        minute: _onceAtMinute,
      );
    }

    // Schedule individual meal reminders
    for (final slot in _mealSlots) {
      if (_mealEnabled[slot.key] == true) {
        await NotificationService.scheduleDailyNotification(
          id: slot.notificationId,
          title: 'Meal Reminder',
          body: 'Time for ${slot.label}!',
          hour: _mealHour[slot.key] ?? slot.defaultHour,
          minute: _mealMinute[slot.key] ?? slot.defaultMinute,
        );
      }
    }
  }

  String _formatTime(int hour, int minute) {
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _pickTime(int currentHour, int currentMinute, void Function(int h, int m) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked != null) {
      onPicked(picked.hour, picked.minute);
      _saveAndSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Reminder')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable Reminders'),
                  value: _masterEnabled,
                  onChanged: (val) {
                    setState(() => _masterEnabled = val);
                    _saveAndSchedule();
                  },
                ),
                const SizedBox(height: 8),
                // Once-at row
                CheckboxListTile(
                  title: Text(
                    'Remind me once at',
                    style: TextStyle(
                      color: _masterEnabled ? null : theme.disabledColor,
                    ),
                  ),
                  secondary: TextButton(
                    onPressed: _masterEnabled
                        ? () => _pickTime(_onceAtHour, _onceAtMinute, (h, m) {
                              setState(() {
                                _onceAtHour = h;
                                _onceAtMinute = m;
                              });
                            })
                        : null,
                    child: Text(_formatTime(_onceAtHour, _onceAtMinute)),
                  ),
                  value: _onceAtEnabled,
                  onChanged: _masterEnabled
                      ? (val) {
                          setState(() => _onceAtEnabled = val ?? false);
                          _saveAndSchedule();
                        }
                      : null,
                ),
                const Divider(),
                // Individual meal slots
                ...List.generate(_mealSlots.length, (i) {
                  final slot = _mealSlots[i];
                  final enabled = _mealEnabled[slot.key] ?? false;
                  final hour = _mealHour[slot.key] ?? slot.defaultHour;
                  final minute = _mealMinute[slot.key] ?? slot.defaultMinute;
                  return CheckboxListTile(
                    title: Text(
                      slot.label,
                      style: TextStyle(
                        fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                        color: _masterEnabled ? null : theme.disabledColor,
                      ),
                    ),
                    secondary: TextButton(
                      onPressed: _masterEnabled
                          ? () => _pickTime(hour, minute, (h, m) {
                                setState(() {
                                  _mealHour[slot.key] = h;
                                  _mealMinute[slot.key] = m;
                                });
                              })
                          : null,
                      child: Text(_formatTime(hour, minute)),
                    ),
                    value: enabled,
                    onChanged: _masterEnabled
                        ? (val) {
                            setState(() => _mealEnabled[slot.key] = val ?? false);
                            _saveAndSchedule();
                          }
                        : null,
                  );
                }),
              ],
            ),
    );
  }
}