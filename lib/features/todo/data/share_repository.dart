import 'package:cloud_firestore/cloud_firestore.dart';

class ShareRepository {
  final FirebaseFirestore _firestore;

  ShareRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Strips the phone number to just digits (no + or spaces).
  String _stripToDigits(String phone) => phone.replaceAll(RegExp(r'[^\d]'), '');

  /// Generates possible phone number variants to search for.
  /// E.g. input "9028230580" → ["+919028230580", "919028230580", "9028230580"]
  /// E.g. input "+919028230580" → ["+919028230580", "919028230580", "9028230580"]
  List<String> _phoneVariants(String input) {
    final digits = _stripToDigits(input);
    final variants = <String>{};

    // Add the original input as-is
    variants.add(input.trim());

    // If input starts with +, also add without +
    if (input.trim().startsWith('+')) {
      variants.add(digits); // e.g. "919028230580"
    }

    // Common country code: +91 (India)
    // If digits start with 91 and have > 10 digits, also try without country code
    if (digits.startsWith('91') && digits.length > 10) {
      final withoutCode = digits.substring(2);
      variants.add(withoutCode); // e.g. "9028230580"
      variants.add('+91$withoutCode'); // e.g. "+919028230580"
    }

    // If digits are exactly 10 (no country code), also try with +91
    if (digits.length == 10) {
      variants.add('+91$digits'); // e.g. "+919028230580"
      variants.add('91$digits'); // e.g. "919028230580"
    }

    return variants.toList();
  }

  /// Finds a user document by phone number or email.
  /// Returns the user data map with 'uid' included, or null if not found.
  Future<Map<String, dynamic>?> findUserByPhone(String input) async {
    // Check if input looks like a phone number (contains digits)
    final hasDigits = RegExp(r'\d').hasMatch(input);

    if (hasDigits) {
      // Try all phone number variants
      final variants = _phoneVariants(input);
      for (final variant in variants) {
        final query = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: variant)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }
      }
    }

    // If not found by phone, try email
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: input)
        .limit(1)
        .get();

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
