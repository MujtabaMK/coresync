import 'package:hive/hive.dart';

part 'membership_model.g.dart';

@HiveType(typeId: 1)
class MembershipModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plan;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime endDate;

  @HiveField(4)
  final bool isActive;

  MembershipModel({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  MembershipModel copyWith({
    String? id,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  static String _planKey(int months) =>
      months == 1 ? '1month' : '${months}months';

  /// Ordered list of plan keys for display (1–24 months).
  static final List<String> displayPlanKeys = [
    for (int i = 1; i <= 24; i++) _planKey(i),
  ];

  static final Map<String, int> planPrices = {
    for (int i = 1; i <= 24; i++) _planKey(i): i * 500,
    '1year': 6000, // backward compat
  };

  static final Map<String, int> planDurations = {
    for (int i = 1; i <= 24; i++) _planKey(i): i * 30,
    '1year': 365, // backward compat
  };

  static final Map<String, String> planLabels = {
    for (int i = 1; i <= 24; i++)
      _planKey(i): i == 12
          ? '1 Year (12 Months)'
          : i == 24
              ? '2 Years (24 Months)'
              : i == 1
                  ? '1 Month'
                  : '$i Months',
    '1year': '1 Year', // backward compat
  };

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get planLabel => planLabels[plan] ?? plan;

  int get price => planPrices[plan] ?? 0;

  int get durationDays => planDurations[plan] ?? 0;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
