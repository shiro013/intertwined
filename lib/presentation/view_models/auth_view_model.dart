import 'package:flutter/material.dart';
import '../../data/repositories/mock/mock_auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final MockAuthRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.signIn(
        email: email,
        password: password,
      );
      final success = response.user != null;
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // For dummy, we just simulate success
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
