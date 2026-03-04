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

  static const Map<String, int> planPrices = {
    '1month': 500,
    '3months': 1200,
    '6months': 2000,
    '1year': 3500,
  };

  static const Map<String, int> planDurations = {
    '1month': 30,
    '3months': 90,
    '6months': 180,
    '1year': 365,
  };

  static const Map<String, String> planLabels = {
    '1month': '1 Month',
    '3months': '3 Months',
    '6months': '6 Months',
    '1year': '1 Year',
  };

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get planLabel => planLabels[plan] ?? plan;

  int get price => planPrices[plan] ?? 0;

  int get durationDays => planDurations[plan] ?? 0;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
