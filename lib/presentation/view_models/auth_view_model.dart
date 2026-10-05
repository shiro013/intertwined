import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SignOutScope;

import '../../core/utils/auth_flash.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';

enum LoginOutcome { success, needsVerification, failed }

enum SignUpOutcome { needsVerification, failed }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  /// Email yang sedang menunggu verifikasi (login dengan akun belum terverifikasi).
  String? _pendingEmail;

  // Penghambat brute-force di sisi aplikasi. Perlindungan sebenarnya ada di
  // server (rate limit Supabase); ini hanya memperlambat tebakan dari app ini.
  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(seconds: 60);
  int _failedLogins = 0;
  DateTime? _lockedUntil;

  // Sign out me-reset seluruh pohon widget (lihat main.dart), jadi ViewModel ini bisa
  // sudah di-dispose saat blok `finally` di bawah jalan.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _pendingEmail;
  String? get email => _repository.currentUser?.email;

  void clearError() => _errorMessage = null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Jalankan aksi; error diterjemahkan jadi pesan ramah dan disimpan di
  /// [errorMessage]. Mengembalikan true kalau sukses.
  Future<bool> _attempt(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = AuthFlowException.from(e).message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------- sign in

  Future<LoginOutcome> signIn(String identifier, String password) async {
    final id = identifier.trim();

    final locked = _lockedUntil;
    if (locked != null && DateTime.now().isBefore(locked)) {
      final seconds = locked.difference(DateTime.now()).inSeconds + 1;
      _errorMessage = 'Too many failed attempts. Try again in $seconds seconds.';
      notifyListeners();
      return LoginOutcome.failed;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.signIn(identifier: id, password: password);
      _failedLogins = 0;
      _lockedUntil = null;
      return LoginOutcome.success;
    } catch (e) {
      final failure = AuthFlowException.from(e);

      if (failure.kind == AuthFailure.emailNotConfirmed) {
        // password sudah benar, tapi email belum diverifikasi
        _pendingEmail = failure.email ?? (Validators.looksLikeEmail(id) ? id : null);
        if (_pendingEmail != null) return LoginOutcome.needsVerification;
      }

      if (failure.kind == AuthFailure.invalidCredentials) {
        _failedLogins++;
        if (_failedLogins >= _maxFailedAttempts) {
          _lockedUntil = DateTime.now().add(_lockDuration);
          _failedLogins = 0;
        }
      }
      _errorMessage = failure.message;
      return LoginOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------- sign up

  Future<SignUpOutcome> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final available = await _repository.isUsernameAvailable(username);
      if (available == false) {
        _errorMessage = 'That username is already taken. Please pick another one.';
        return SignUpOutcome.failed;
      }

      final response = await _repository.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (response.session != null) {
        // Server TIDAK mewajibkan verifikasi email ("Confirm email" mati) sehingga
        // Supabase langsung memberi sesi. Aplikasi menolak (fail closed): sesi
        // dibuang dan user diberi tahu, bukan dibiarkan masuk tanpa kode.
        const message = 'Sign-up is unavailable: email verification is not enabled '
            'on the server. Ask the administrator to turn on "Confirm email" '
            'in Supabase (Authentication > Providers > Email).';
        debugPrint('SECURITY: sign up returned a session. Enable "Confirm email".');
        AuthFlash.set(message); // sign out me-reset layar; pesan dititipkan di sini
        _errorMessage = message;
        try {
          await _repository.signOut();
        } catch (_) {}
        return SignUpOutcome.failed;
      }
      _pendingEmail = email;
      return SignUpOutcome.needsVerification;
    } catch (e) {
      _errorMessage = AuthFlowException.from(e).message;
      return SignUpOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifySignupCode(String email, String code) =>
      _attempt(() => _repository.verifySignupCode(email: email, code: code.trim()));

  Future<bool> resendSignupCode(String email) =>
      _attempt(() => _repository.resendSignupCode(email));

  // ------------------------------------------------------------ lupa password

  Future<bool> requestPasswordReset(String email) =>
      _attempt(() => _repository.requestPasswordReset(email));

  Future<bool> verifyRecoveryCode(String email, String code) =>
      _attempt(() => _repository.verifyRecoveryCode(email: email, code: code.trim()));

  Future<bool> setNewPassword(String newPassword) =>
      _attempt(() => _repository.setNewPassword(newPassword));

  /// Setelah reset: keluarkan SEMUA perangkat (termasuk sesi recovery ini).
  /// AuthGate/root akan otomatis kembali ke layar login.
  Future<bool> signOutEverywhere() =>
      _attempt(() => _repository.signOut(scope: SignOutScope.global));

  // ----------------------------------------------------- ganti password (login)

  Future<bool> verifyCurrentPassword(String password) =>
      _attempt(() => _repository.verifyCurrentPassword(password));

  Future<bool> sendChangePasswordCode() =>
      _attempt(() => _repository.sendChangePasswordCode());

  /// Hanya true jika server menyatakan kodenya benar.
  Future<bool> verifyChangePasswordCode(String code) =>
      _attempt(() => _repository.verifyChangePasswordCode(code.trim()));

  Future<bool> changePassword(String newPassword) =>
      _attempt(() => _repository.changePassword(newPassword));

  // ---------------------------------------------------------------- sign out

  Future<bool> signOut() => _attempt(() => _repository.signOut());
}
