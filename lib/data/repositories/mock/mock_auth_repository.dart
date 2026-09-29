import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock Auth Repository to decouple the app from Supabase.
/// Instead of interacting with the real API, it uses simple hardcoded logic.
class MockAuthRepository {
  // Mock user session
  User? _currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'test@test.com' && password == 'password123') {
      _currentUser = User(
        id: 'mock-user-id',
        email: email,
        aud: 'mock-audience',
        appMetadata: {},
        userMetadata: {'username': 'Test User'},
        createdAt: DateTime.now().toIso8601String(),
      );
      return AuthResponse(
        user: _currentUser,
        session: Session(
          accessToken: 'mock-token',
          refreshToken: 'mock-refresh',
          expiresIn: 3600,
          tokenType: 'Bearer',
          user: _currentUser!,
        ),
      );
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  User? get currentUser => _currentUser;
}
