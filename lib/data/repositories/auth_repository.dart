import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthFailure {
  invalidCredentials,
  emailNotConfirmed,
  invalidCode,
  rateLimited,
  weakPassword,
  samePassword,
  usernameTaken,
  emailTaken,
  network,
  unavailable,
  other,
}

/// Error auth yang sudah diterjemahkan jadi pesan ramah dan TIDAK membocorkan
/// detail internal (mis. apakah sebuah akun ada atau tidak).
class AuthFlowException implements Exception {
  final AuthFailure kind;
  final String message;

  /// Hanya diisi untuk emailNotConfirmed (password sudah terbukti benar).
  final String? email;

  const AuthFlowException(this.kind, this.message, {this.email});

  const AuthFlowException.invalidCredentials()
      : this(
          AuthFailure.invalidCredentials,
          'Incorrect username/email or password.',
        );

  factory AuthFlowException.from(Object error) {
    if (error is AuthFlowException) return error;

    if (error is SocketException) {
      return const AuthFlowException(
        AuthFailure.network,
        'No internet connection. Please check your network and try again.',
      );
    }

    if (error is FunctionException) {
      final details = error.details;
      final code = details is Map ? details['error']?.toString() : null;
      if (error.status == 403 && code == 'email_not_confirmed') {
        return AuthFlowException(
          AuthFailure.emailNotConfirmed,
          'Please verify your email first.',
          email: details is Map ? details['email']?.toString() : null,
        );
      }
      if (error.status == 429) return _rateLimited();
      if (error.status == 404) {
        return const AuthFlowException(
          AuthFailure.unavailable,
          'Username login is not available right now. Please sign in with your email instead.',
        );
      }
      if (error.status == 401 || error.status == 400) return _invalidCredentials();
      return const AuthFlowException(
        AuthFailure.other,
        'Something went wrong. Please try again.',
      );
    }

    if (error is AuthException) {
      final code = (error.code ?? '').toLowerCase();
      final msg = error.message.toLowerCase();

      if (code == 'invalid_credentials' || msg.contains('invalid login credentials')) {
        return _invalidCredentials();
      }
      if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
        return const AuthFlowException(
          AuthFailure.emailNotConfirmed,
          'Please verify your email first.',
        );
      }
      if (error.statusCode == '429' ||
          code.contains('rate_limit') ||
          msg.contains('rate limit') ||
          msg.contains('too many')) {
        return _rateLimited();
      }
      if (code == 'otp_expired' ||
          code == 'reauthentication_not_valid' ||
          msg.contains('expired') ||
          msg.contains('token has expired or is invalid') ||
          (msg.contains('invalid') && msg.contains('token'))) {
        return const AuthFlowException(
          AuthFailure.invalidCode,
          'That code is incorrect or has expired. Request a new one and try again.',
        );
      }
      if (code == 'reauthentication_needed') {
        return const AuthFlowException(
          AuthFailure.invalidCode,
          'Enter the verification code we emailed you.',
        );
      }
      if (code == 'same_password' || msg.contains('different from the old password')) {
        return const AuthFlowException(
          AuthFailure.samePassword,
          'Your new password must be different from your current one.',
        );
      }
      if (code == 'weak_password' || msg.contains('weak') || msg.contains('at least')) {
        return const AuthFlowException(
          AuthFailure.weakPassword,
          'That password is too weak. Use at least 8 characters with letters and numbers.',
        );
      }
      if (code == 'user_already_exists' || code == 'email_exists' || msg.contains('already registered')) {
        return const AuthFlowException(
          AuthFailure.emailTaken,
          'That email is already registered. Try signing in or resetting your password.',
        );
      }
      // Trigger profiles gagal karena username unik sudah dipakai
      if (msg.contains('database error saving new user')) {
        return const AuthFlowException(
          AuthFailure.usernameTaken,
          'That username is already taken. Please pick another one.',
        );
      }
    }

    debugPrint('Unmapped auth error: $error');
    return const AuthFlowException(
      AuthFailure.other,
      'Something went wrong. Please try again.',
    );
  }

  static AuthFlowException _invalidCredentials() =>
      const AuthFlowException.invalidCredentials();

  static AuthFlowException _rateLimited() => const AuthFlowException(
        AuthFailure.rateLimited,
        'Too many attempts. Please wait a few minutes and try again.',
      );

  @override
  String toString() => message;
}

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _usernameLoginFunction = 'login-with-username';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ---------------------------------------------------------------- sign up

  /// true = tersedia, false = sudah dipakai, null = tidak bisa dicek
  /// (mis. SQL 03 belum dijalankan). Server tetap menolak duplikat.
  Future<bool?> isUsernameAvailable(String username) async {
    try {
      final result = await _client.rpc(
        'is_username_available',
        params: {'p_username': username},
      );
      return result == true;
    } catch (e) {
      debugPrint('isUsernameAvailable unavailable: $e');
      return null;
    }
  }

  /// Dengan "Confirm email" aktif di Supabase, response TIDAK berisi session:
  /// akun baru harus memasukkan kode dari email lebih dulu.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Baris `profiles` dibuat oleh trigger database dari metadata `username`.
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  Future<AuthResponse> verifySignupCode({
    required String email,
    required String code,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  Future<void> resendSignupCode(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  // ---------------------------------------------------------------- sign in

  /// [identifier] boleh email ATAU username.
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      if (identifier.contains('@')) {
        await _client.auth.signInWithPassword(email: identifier, password: password);
        return;
      }

      // Username -> dicek di server (Edge Function). Email user TIDAK pernah
      // dikirim ke aplikasi, jadi username tidak bisa dipakai untuk mencari email.
      final response = await _client.functions.invoke(
        _usernameLoginFunction,
        body: {'identifier': identifier, 'password': password},
      );
      final data = response.data;
      final refreshToken = data is Map ? data['refresh_token'] : null;
      if (refreshToken is! String || refreshToken.isEmpty) {
        throw const AuthFlowException.invalidCredentials();
      }
      await _client.auth.setSession(refreshToken);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    try {
      await _client.auth.signOut(scope: scope);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  // --------------------------------------------------- lupa password (kode)

  /// Selalu berhasil secara kasat mata, juga untuk email yang tidak terdaftar
  /// (Supabase tidak membocorkan keberadaan akun).
  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Kode benar -> sesi "recovery" dibuat, cukup untuk mengganti password.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  // ------------------------------------- ganti password (sudah login, kode)

  /// Langkah 1: pastikan yang menekan tombol memang tahu password saat ini.
  Future<void> verifyCurrentPassword(String password) async {
    final email = currentUser?.email;
    if (email == null) {
      throw const AuthFlowException(
        AuthFailure.other,
        'You need to be signed in to change your password.',
      );
    }
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Langkah 2: kirim kode (nonce) ke email akun.
  Future<void> sendReauthenticationCode() async {
    try {
      await _client.auth.reauthenticate();
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Langkah 3: ganti password dengan kode, lalu keluarkan perangkat lain.
  Future<void> changePassword({
    required String newPassword,
    required String code,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword, nonce: code),
      );
    } catch (e) {
      throw AuthFlowException.from(e);
    }

    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (e) {
      debugPrint('Sign out other sessions failed: $e');
    }
  }
}
