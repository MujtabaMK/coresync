import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/membership_model.dart';

class GymRepository {
  GymRepository({required this.uid});

  final String uid;

  final _firestore = FirebaseFirestore.instance;

  // Firestore references
  DocumentReference get _userDoc => _firestore.collection('users').doc(uid);
  CollectionReference get _attendanceCol => _userDoc.collection('gym_attendance');
  CollectionReference get _membershipCol => _userDoc.collection('gym_memberships');
  CollectionReference get _waterCol => _userDoc.collection('gym_water');

  // Local settings box (reminders are device-specific)
  Box? _gymSettingsBox;

  Future<Box> _getGymSettingsBox() async {
    if (_gymSettingsBox != null && _gymSettingsBox!.isOpen) {
      return _gymSettingsBox!;
    }
    _gymSettingsBox = await HiveService.openBox(AppConstants.gymSettingsBox);
    return _gymSettingsBox!;
  }

  Future<Box> getGymSettingsBox() => _getGymSettingsBox();

  // ── Membership ──

  Future<MembershipModel?> getActiveMembership() async {
    final snapshot = await _membershipCol
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final m = _membershipFromDoc(doc);
    if (m.isExpired) return null;
    return m;
  }

  Future<void> saveMembership(MembershipModel membership) async {
    // Deactivate existing active memberships
    final active = await _membershipCol
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in active.docs) {
      await doc.reference.update({'isActive': false});
    }
    await _membershipCol.doc(membership.id).set({
      'plan': membership.plan,
      'startDate': Timestamp.fromDate(membership.startDate),
      'endDate': Timestamp.fromDate(membership.endDate),
      'isActive': membership.isActive,
    });
  }

  MembershipModel _membershipFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipModel(
      id: doc.id,
      plan: data['plan'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
    );
  }

  // ── Attendance ──

  Future<List<Map<String, dynamic>>> getAllAttendanceRaw() async {
    final snapshot = await _attendanceCol.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'date': (data['date'] as Timestamp).toDate(),
        'isPresent': data['isPresent'] as bool,
      };
    }).toList();
  }

  Future<void> markAttendance(DateTime date, bool isPresent) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _attendanceCol.doc(key).set({
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'isPresent': isPresent,
    });
  }

  Future<void> deleteAttendance(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _attendanceCol.doc(key).delete();
  }

  Future<void> deleteAllAttendance() async {
    final snapshot = await _attendanceCol.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Map<DateTime, bool>> getAttendanceMap() async {
    final snapshot = await _attendanceCol.get();
    final map = <DateTime, bool>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      map[normalizedDate] = data['isPresent'] as bool;
    }
    return map;
  }

  Future<int> getPresentCount() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getAbsentCount() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<List<DateTime>> getPresentDates() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: true)
        .get();
    final dates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return DateTime(date.year, date.month, date.day);
    }).toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Future<List<DateTime>> getAbsentDates() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: false)
        .get();
    final dates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return DateTime(date.year, date.month, date.day);
    }).toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  // ── Water Intake ──

  Future<int> getWaterIntakeForDate(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = await _waterCol.doc(key).get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['glasses'] as int? ?? 0;
  }

  Future<void> addWaterGlass(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = _waterCol.doc(key);
    final snapshot = await doc.get();
    final current = snapshot.exists
        ? ((snapshot.data() as Map<String, dynamic>?)?['glasses'] as int? ?? 0)
        : 0;
    await doc.set({'glasses': current + 1});
  }

  Future<void> resetWaterIntake(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _waterCol.doc(key).set({'glasses': 0});
  }

  // ── User Metrics ──

  Future<void> saveUserMetrics({
    required double height,
    required double weight,
  }) async {
    await _userDoc.set({
      'userHeight': height,
      'userWeight': weight,
    }, SetOptions(merge: true));
  }

  Future<Map<String, double?>> getUserMetrics() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return {'height': null, 'weight': null};
    final data = doc.data() as Map<String, dynamic>?;
    return {
      'height': (data?['userHeight'] as num?)?.toDouble(),
      'weight': (data?['userWeight'] as num?)?.toDouble(),
    };
  }

  // ── Reminder Settings (stays local in Hive) ──

  Future<Map<String, dynamic>> getReminderSettings(String hivePrefix) async {
    final box = await _getGymSettingsBox();
    return {
      'enabled': box.get('${hivePrefix}_enabled', defaultValue: false) as bool,
      'hour': box.get('${hivePrefix}_hour', defaultValue: 8) as int,
      'minute': box.get('${hivePrefix}_minute', defaultValue: 0) as int,
      'frequency': box.get('${hivePrefix}_frequency', defaultValue: 'weekly') as String,
      'dayOfWeek': box.get('${hivePrefix}_dayOfWeek', defaultValue: 1) as int,
      'dayOfMonth': box.get('${hivePrefix}_dayOfMonth', defaultValue: 1) as int,
    };
  }

  Future<void> saveReminderSettings(
    String hivePrefix,
    Map<String, dynamic> settings,
  ) async {
    final box = await _getGymSettingsBox();
    for (final entry in settings.entries) {
      await box.put('${hivePrefix}_${entry.key}', entry.value);
    }
  }
}