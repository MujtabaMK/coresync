import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../domain/habit_model.dart';

class HabitRepository {
  HabitRepository({required this.uid});

  final String uid;
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _habitsCol =>
      _firestore.collection('users').doc(uid).collection('habits');

  static String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Stream of active (non-archived) habits ordered by creation date.
  Stream<List<HabitModel>> watchHabits() {
    return _habitsCol.snapshots().map((snap) {
      final List<HabitModel> all = [];
      for (final doc in snap.docs) {
        try {
          all.add(HabitModel.fromFirestore(doc));
        } catch (_) {
          // Skip documents that fail to parse
        }
      }
      final active = all.where((h) => !h.isArchived).toList();
      active.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return active;
    });
  }

  /// Stream of archived habits.
  Stream<List<HabitModel>> watchArchivedHabits() {
    return _habitsCol.snapshots().map((snap) {
      final List<HabitModel> all = [];
      for (final doc in snap.docs) {
        try {
          all.add(HabitModel.fromFirestore(doc));
        } catch (_) {
          // Skip documents that fail to parse
        }
      }
      final archived = all.where((h) => h.isArchived).toList();
      archived.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return archived;
    });
  }

  /// Add a new habit, returns the generated ID.
  Future<String> addHabit(HabitModel habit) async {
    final id = const Uuid().v4();
    final data = habit.copyWith(id: id).toFirestore();
    await _habitsCol.doc(id).set(data);
    return id;
  }

  /// Update an existing habit.
  Future<void> updateHabit(HabitModel habit) async {
    await _habitsCol.doc(habit.id).update(habit.toFirestore());
  }

  /// Delete a habit permanently.
  Future<void> deleteHabit(String id) async {
    await _habitsCol.doc(id).delete();
  }

  /// Increment completion count for a date using FieldValue.increment.
  Future<void> incrementCompletion(
    String habitId,
    DateTime date, {
    int amount = 1,
  }) async {
    final key = 'completions.${_dateKey(date)}';
    await _habitsCol.doc(habitId).update({
      key: FieldValue.increment(amount),
    });
  }

  /// Decrement completion count for a date (minimum 0).
  Future<void> decrementCompletion(String habitId, DateTime date) async {
    final doc = await _habitsCol.doc(habitId).get();
    if (!doc.exists) return;
    final habit = HabitModel.fromFirestore(doc);
    final current = habit.completionsOnDate(date);
    final newVal = (current - 1).clamp(0, current);
    await _habitsCol.doc(habitId).update({
      'completions.${_dateKey(date)}': newVal,
    });
  }

  /// Toggle completion for oneTime habits (0→1, >=1→0).
  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final doc = await _habitsCol.doc(habitId).get();
    if (!doc.exists) return;
    final habit = HabitModel.fromFirestore(doc);
    final current = habit.completionsOnDate(date);
    await _habitsCol.doc(habitId).update({
      'completions.${_dateKey(date)}': current >= 1 ? 0 : 1,
    });
  }

  /// Save a meaning (question + answer) for a habit.
  Future<void> saveMeaning(String habitId, String question, String answer) async {
    await _habitsCol.doc(habitId).update({
      'meanings.$question': answer,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a meaning from a habit.
  Future<void> deleteMeaning(String habitId, String question) async {
    await _habitsCol.doc(habitId).update({
      'meanings.$question': FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Archive or unarchive a habit.
  Future<void> setArchived(String habitId, bool archived) async {
    await _habitsCol.doc(habitId).update({
      'isArchived': archived,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
