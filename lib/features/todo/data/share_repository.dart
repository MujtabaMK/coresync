import 'package:cloud_firestore/cloud_firestore.dart';

class ShareRepository {
  final FirebaseFirestore _firestore;

  ShareRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Finds a user document by phone number or email.
  /// Returns the user data map with 'uid' included, or null if not found.
  Future<Map<String, dynamic>?> findUserByPhone(String input) async {
    // Try phone number first
    var query = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: input)
        .limit(1)
        .get();

    // If not found by phone, try email
    if (query.docs.isEmpty) {
      query = await _firestore
          .collection('users')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();
    }

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final data = doc.data();
    data['uid'] = doc.id;
    return data;
  }

  /// Adds [targetUid] to the sharedWith array of the task document.
  Future<void> shareTask(String taskId, String targetUid) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'sharedWith': FieldValue.arrayUnion([targetUid]),
    });
  }

  /// Removes [targetUid] from the sharedWith array of the task document.
  Future<void> unshareTask(String taskId, String targetUid) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'sharedWith': FieldValue.arrayRemove([targetUid]),
    });
  }
}
