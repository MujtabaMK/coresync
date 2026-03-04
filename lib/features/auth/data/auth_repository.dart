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
    final doc = await docRef.get();
    if (!doc.exists) {
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
      await docRef.set(userModel.toFirestore());
    }
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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
