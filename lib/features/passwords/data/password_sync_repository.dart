import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/crypto_service.dart';
import '../domain/password_entry_model.dart';

class PasswordSyncRepository {
  final FirebaseFirestore _firestore;

  PasswordSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _passwordsRef(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.passwordsSyncCollection);

  Future<void> pushPassword(
      String uid, PasswordEntryModel entry, Key key) async {
    await _passwordsRef(uid).doc(entry.id).set({
      'passwordFor': CryptoService.encryptField(entry.passwordFor, key),
      'username': CryptoService.encryptField(entry.username, key),
      'password': CryptoService.encryptField(entry.password, key),
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.updatedAt),
    });
  }

  Future<void> deletePassword(String uid, String passwordId) async {
    await _passwordsRef(uid).doc(passwordId).delete();
  }

  Future<List<PasswordEntryModel>> fetchAllPasswords(
      String uid, Key key) async {
    final snapshot = await _passwordsRef(uid).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PasswordEntryModel(
        id: doc.id,
        passwordFor: CryptoService.decryptField(data['passwordFor'], key),
        username: CryptoService.decryptField(data['username'], key),
        password: CryptoService.decryptField(data['password'], key),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
