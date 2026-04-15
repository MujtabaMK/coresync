import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum ExecutionType { oneTime, multiple, trackVolume, dayCounter }

enum FrequencyMode { byDays, timesPerWeek }

class HabitModel extends Equatable {
  const HabitModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.icon = '\u{1F3AF}',
    this.executionType = ExecutionType.oneTime,
    this.dailyVolume = 1,
    this.volumePerPress = 1,
    required this.startDate,
    this.endDate,
    this.frequencyMode = FrequencyMode.byDays,
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7],
    this.timesPerWeek = 7,
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7],
    this.completions = const {},
    this.meanings = const {},
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String icon;
  final ExecutionType executionType;
  final int dailyVolume;
  final int volumePerPress;
  final DateTime startDate;
  final DateTime? endDate;
  final FrequencyMode frequencyMode;
  final List<int> selectedDays;
  final int timesPerWeek;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final List<int> reminderDays;
  final Map<String, int> completions;
  final Map<String, String> meanings;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Computed helpers ──

  static String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  int completionsOnDate(DateTime date) => completions[_dateKey(date)] ?? 0;

  bool isScheduledOn(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    if (dateOnly.isBefore(startOnly)) return false;
    if (endDate != null) {
      final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }

    if (frequencyMode == FrequencyMode.byDays) {
      return selectedDays.contains(date.weekday);
    }
    // For timesPerWeek, always show the habit – the user decides which days
    return true;
  }

  bool isCompletedOn(DateTime date) {
    final count = completionsOnDate(date);
    switch (executionType) {
      case ExecutionType.oneTime:
      case ExecutionType.dayCounter:
        return count >= 1;
      case ExecutionType.multiple:
      case ExecutionType.trackVolume:
        return count >= dailyVolume;
    }
  }

  int get currentStreak {
    var streak = 0;
    var day = DateTime.now();
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);

    // If today isn't scheduled, start from yesterday
    if (!isScheduledOn(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (true) {
      // Stop if we've gone before the habit's start date
      if (DateTime(day.year, day.month, day.day).isBefore(startOnly)) break;

      if (!isScheduledOn(day)) {
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      if (isCompletedOn(day)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get bestStreak {
    var best = 0;
    var current = 0;
    final sortedDates = completions.keys.toList()..sort();
    for (final key in sortedDates) {
      final count = completions[key] ?? 0;
      if (count <= 0) continue;
      final date = DateTime.tryParse(key);
      if (date == null) continue;
      if (!isScheduledOn(date)) continue;
      if (isCompletedOn(date)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    // Also check current streak in case it's the best
    final cs = currentStreak;
    if (cs > best) best = cs;
    return best;
  }

  int get totalDaysDone {
    int count = 0;
    for (final entry in completions.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      if (entry.value > 0 && isScheduledOn(date) && isCompletedOn(date)) {
        count++;
      }
    }
    return count;
  }

  int daysCompletedInMonth(int year, int month) {
    int count = 0;
    for (final entry in completions.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      if (date.year == year && date.month == month && entry.value > 0 && isCompletedOn(date)) {
        count++;
      }
    }
    return count;
  }

  /// Last 7 days completion status (index 0 = 6 days ago, index 6 = today).
  List<bool?> get weeklyCompletion {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      if (!isScheduledOn(day)) return null; // not scheduled
      return isCompletedOn(day);
    });
  }

  // ── Firestore ──

  factory HabitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HabitModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      icon: data['icon'] as String? ?? '\u{1F3AF}',
      executionType: ExecutionType.values.firstWhere(
        (e) => e.name == (data['executionType'] as String?),
        orElse: () => ExecutionType.oneTime,
      ),
      dailyVolume: (data['dailyVolume'] as num?)?.toInt() ?? 1,
      volumePerPress: (data['volumePerPress'] as num?)?.toInt() ?? 1,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      frequencyMode: FrequencyMode.values.firstWhere(
        (e) => e.name == (data['frequencyMode'] as String?),
        orElse: () => FrequencyMode.byDays,
      ),
      selectedDays: (data['selectedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      timesPerWeek: (data['timesPerWeek'] as num?)?.toInt() ?? 7,
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderHour: (data['reminderHour'] as num?)?.toInt() ?? 9,
      reminderMinute: (data['reminderMinute'] as num?)?.toInt() ?? 0,
      reminderDays: (data['reminderDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      completions: (data['completions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
          const {},
      meanings: (data['meanings'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as String),
            ) ??
          const {},
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'icon': icon,
      'executionType': executionType.name,
      'dailyVolume': dailyVolume,
      'volumePerPress': volumePerPress,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'frequencyMode': frequencyMode.name,
      'selectedDays': selectedDays,
      'timesPerWeek': timesPerWeek,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'reminderDays': reminderDays,
      'completions': completions,
      'meanings': meanings,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HabitModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? icon,
    ExecutionType? executionType,
    int? dailyVolume,
    int? volumePerPress,
    DateTime? startDate,
    DateTime? Function()? endDate,
    FrequencyMode? frequencyMode,
    List<int>? selectedDays,
    int? timesPerWeek,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    List<int>? reminderDays,
    Map<String, int>? completions,
    Map<String, String>? meanings,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      executionType: executionType ?? this.executionType,
      dailyVolume: dailyVolume ?? this.dailyVolume,
      volumePerPress: volumePerPress ?? this.volumePerPress,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      frequencyMode: frequencyMode ?? this.frequencyMode,
      selectedDays: selectedDays ?? this.selectedDays,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderDays: reminderDays ?? this.reminderDays,
      completions: completions ?? this.completions,
      meanings: meanings ?? this.meanings,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        icon,
        executionType,
        dailyVolume,
        volumePerPress,
        startDate,
        endDate,
        frequencyMode,
        selectedDays,
        timesPerWeek,
        reminderEnabled,
        reminderHour,
        reminderMinute,
        reminderDays,
        completions,
        meanings,
        isArchived,
        createdAt,
        updatedAt,
      ];
}
