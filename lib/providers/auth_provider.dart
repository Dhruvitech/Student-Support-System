import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:studentsupportsystem/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          _currentUser = await _authService.getCurrentUserData();
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing auth listener: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String classGroup = '',
    String enrollmentNumber = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        classGroup: classGroup,
        enrollmentNumber: enrollmentNumber,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String emailOrEnrollment,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmailOrEnrollment(
        emailOrEnrollment: emailOrEnrollment,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }
}
