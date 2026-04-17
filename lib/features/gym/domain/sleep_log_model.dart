enum SleepQuality {
  poor('Poor'),
  fair('Fair'),
  good('Good'),
  excellent('Excellent');

  const SleepQuality(this.label);
  final String label;
}

class SleepLogModel {
  SleepLogModel({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    this.quality,
    this.notes,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final SleepQuality? quality;
  final String? notes;
  final DateTime loggedAt;

  Duration get duration => wakeTime.difference(sleepTime);

  /// Auto-detect period label from bedtime hour.
  String get period {
    final h = sleepTime.hour;
    if (h >= 21 || h < 4) return 'Night';
    if (h >= 4 && h < 6) return 'Dawn';
    if (h >= 6 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    return 'Evening'; // 17-20
  }

  String get durationFormatted {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  Map<String, dynamic> toFirestore() => {
        'sleepTime': sleepTime.millisecondsSinceEpoch,
        'wakeTime': wakeTime.millisecondsSinceEpoch,
        'quality': quality?.name,
        'notes': notes,
        'loggedAt': loggedAt.millisecondsSinceEpoch,
      };

  factory SleepLogModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return SleepLogModel(
      id: id,
      sleepTime: DateTime.fromMillisecondsSinceEpoch(
          (data['sleepTime'] as num).toInt()),
      wakeTime: DateTime.fromMillisecondsSinceEpoch(
          (data['wakeTime'] as num).toInt()),
      quality: data['quality'] != null
          ? SleepQuality.values.firstWhere(
              (e) => e.name == data['quality'],
              orElse: () => SleepQuality.good,
            )
          : null,
      notes: data['notes'] as String?,
      loggedAt: data['loggedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['loggedAt'] as num).toInt())
          : DateTime.now(),
    );
  }
}
