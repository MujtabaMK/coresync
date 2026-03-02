import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/attendance_model.dart';
import '../domain/membership_model.dart';

class GymRepository {
  Box<MembershipModel>? _membershipBox;
  Box<AttendanceModel>? _attendanceBox;

  Future<Box<MembershipModel>> _getMembershipBox() async {
    if (_membershipBox != null && _membershipBox!.isOpen) {
      return _membershipBox!;
    }
    _membershipBox = await HiveService.openBox<MembershipModel>(
      AppConstants.membershipBox,
    );
    return _membershipBox!;
  }

  Future<Box<AttendanceModel>> _getAttendanceBox() async {
    if (_attendanceBox != null && _attendanceBox!.isOpen) {
      return _attendanceBox!;
    }
    _attendanceBox = await HiveService.openBox<AttendanceModel>(
      AppConstants.attendanceBox,
    );
    return _attendanceBox!;
  }

  Future<MembershipModel?> getActiveMembership() async {
    final box = await _getMembershipBox();
    if (box.isEmpty) return null;
    try {
      return box.values.firstWhere((m) => m.isActive && !m.isExpired);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMembership(MembershipModel membership) async {
    final box = await _getMembershipBox();
    // Deactivate any existing active memberships
    for (final key in box.keys) {
      final existing = box.get(key);
      if (existing != null && existing.isActive) {
        await box.put(
          key,
          existing.copyWith(isActive: false),
        );
      }
    }
    await box.put(membership.id, membership);
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final box = await _getAttendanceBox();
    return box.values.toList();
  }

  Future<void> markAttendance(DateTime date, bool isPresent) async {
    final box = await _getAttendanceBox();
    final key = DateFormat('yyyy-MM-dd').format(date);
    final attendance = AttendanceModel(
      date: DateTime(date.year, date.month, date.day),
      isPresent: isPresent,
    );
    await box.put(key, attendance);
  }

  Future<AttendanceModel?> getAttendanceForDate(DateTime date) async {
    final box = await _getAttendanceBox();
    final key = DateFormat('yyyy-MM-dd').format(date);
    return box.get(key);
  }

  Future<Map<DateTime, bool>> getAttendanceMap() async {
    final box = await _getAttendanceBox();
    final map = <DateTime, bool>{};
    for (final attendance in box.values) {
      final normalizedDate = DateTime(
        attendance.date.year,
        attendance.date.month,
        attendance.date.day,
      );
      map[normalizedDate] = attendance.isPresent;
    }
    return map;
  }

  Future<int> getPresentCount() async {
    final box = await _getAttendanceBox();
    return box.values.where((a) => a.isPresent).length;
  }

  Future<int> getAbsentCount() async {
    final box = await _getAttendanceBox();
    return box.values.where((a) => !a.isPresent).length;
  }
}
