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

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get planLabel {
    switch (plan) {
      case '1month':
        return '1 Month';
      case '3months':
        return '3 Months';
      case '6months':
        return '6 Months';
      case '1year':
        return '1 Year';
      default:
        return plan;
    }
  }

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
