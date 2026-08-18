import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String classGroup = '',
    String enrollmentNumber = '', // NEW
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final now = DateTime.now();
    final userData = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      classGroup: classGroup,
      enrollmentNumber: enrollmentNumber, // CHANGED (was '')
      password: '',
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set(userData.toJson());
    return userData;
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      
      if (!doc.exists || doc.data() == null) {
        throw Exception('User data not found. Please sign up again.');
      }
      
      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (_) {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        if ((data['password'] as String? ?? '') == password) {
          return UserModel.fromJson(data);
        }
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}