import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/user_model.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createUserDocument(
    User user, {
    String? firstName,
    String? lastName,
    required String phoneNumber,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);
    final displayName = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      displayName: displayName.isNotEmpty ? displayName : null,
      createdAt: DateTime.now(),
    );
    await docRef.set(userModel.toFirestore(), SetOptions(merge: true));

    // Also write minimal data to public lookup collection
    await _firestore.collection('user_lookup').doc(user.uid).set({
      'email': user.email ?? '',
      'phoneNumber': phoneNumber,
    });
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Check if an email is registered (works without authentication).
  Future<bool> isEmailRegisteredInLookup(String email) async {
    final query = await _firestore
        .collection('user_lookup')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Returns true if the phone number is already used by another account.
  /// Uses public lookup collection — works without authentication.
  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final query = await _firestore
        .collection('user_lookup')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Returns true if the email is registered in Firebase Auth.
  Future<bool> isEmailRegistered(String email) async {
    // ignore: deprecated_member_use
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
