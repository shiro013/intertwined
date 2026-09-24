import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _authService.currentUser;

  Future<bool> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Email and password are required';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      // Add timeout to prevent infinite loading state
      await _authService.signIn(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: Please check your connection or credentials';
      debugPrint('Sign-in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      _errorMessage = 'All fields are required';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      ).timeout(const Duration(seconds: 15));
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Sign-up failed: $e';
      debugPrint('Sign-up error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
