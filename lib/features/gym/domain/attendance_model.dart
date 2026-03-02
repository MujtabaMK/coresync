import 'package:hive/hive.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: 2)
class AttendanceModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final bool isPresent;

  AttendanceModel({
    required this.date,
    required this.isPresent,
  });
}
