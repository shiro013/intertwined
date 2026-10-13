import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';
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
  mfaCodeInvalid, // kode authenticator salah / kedaluwarsa
  mfaRequired, // aksi butuh sesi yang sudah lolos 2FA (AAL2)
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

      // --- 2FA (TOTP)
      if (code == 'mfa_verification_failed' ||
          code == 'mfa_verification_rejected' ||
          msg.contains('invalid totp')) {
        return const AuthFlowException(
          AuthFailure.mfaCodeInvalid,
          'That authenticator code is incorrect. Check your app and try again.',
        );
      }
      if (code == 'mfa_challenge_expired') {
        return const AuthFlowException(
          AuthFailure.mfaCodeInvalid,
          'That code has expired. Enter the newest code shown in your authenticator app.',
        );
      }
      if (code == 'insufficient_aal') {
        return const AuthFlowException(
          AuthFailure.mfaRequired,
          'Please confirm your authenticator code first.',
        );
      }
      if (code == 'mfa_totp_enroll_not_enabled' || code == 'mfa_totp_verify_not_enabled') {
        return const AuthFlowException(
          AuthFailure.unavailable,
          'Two-factor authentication is not enabled on the server yet.',
        );
      }
      if (code == 'too_many_enrolled_mfa_factors') {
        return const AuthFlowException(
          AuthFailure.other,
          'Two-factor authentication is already set up for this account.',
        );
      }


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

/// Data yang ditampilkan saat memasang 2FA: QR (dari [uri]) dan kunci manual.
class MfaEnrollment {
  final String factorId;
  final String secret;
  final String uri;

  const MfaEnrollment({
    required this.factorId,
    required this.secret,
    required this.uri,
  });
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
        // Dicek lewat klien SEMENTARA (sesi hanya di memori), bukan sesi aplikasi.
    // signInWithPassword di klien utama akan MENGGANTI sesi: pengguna 2FA turun
    // dari AAL2 ke AAL1 dan terlempar ke layar kode di tengah proses.
    final probe = GoTrueClient(
      url: '${SupabaseConfig.supabaseUrl}/auth/v1',
      headers: {
        'apikey': SupabaseConfig.supabaseKey,
        'Authorization': 'Bearer ${SupabaseConfig.supabaseKey}',
      },
      autoRefreshToken: false,
    );
    try {
      await probe.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw AuthFlowException.from(e);
    } finally {
      try {
        await probe.signOut(); // cabut sesi sementara itu di server
      } catch (e) {
        debugPrint('Probe sign out failed: $e');
      }
      probe.dispose();
    }
  }

  /// Langkah 2: kirim kode ke email akun yang sedang login.
  ///
  /// Sengaja memakai alur "recovery" (bukan reauthenticate + nonce): nonce di
  /// updateUser hanya dicek Supabase untuk sesi yang lebih tua dari ~24 jam dan
  /// DIABAIKAN begitu saja untuk sesi baru, sehingga kode salah pun lolos.
  /// verifyOTP selalu memeriksa kode di server dan gagal jika kodenya salah.
  Future<void> sendChangePasswordCode() async {
    final email = _requireEmail();
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Langkah 3: periksa kode. Salah/kedaluwarsa -> melempar error dan langkah
  /// ganti password TIDAK dijalankan.
  Future<void> verifyChangePasswordCode(String code) async {
    final email = _requireEmail();
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

  /// Langkah 4 (hanya setelah kode terverifikasi): ganti password, lalu keluarkan
  /// perangkat lain.
  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthFlowException.from(e);
    }

    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (e) {
      debugPrint('Sign out other sessions failed: $e');
    }
  }

  String _requireEmail() {
    final email = currentUser?.email;
    if (email == null) {
      throw const AuthFlowException(
        AuthFailure.other,
        'You need to be signed in to change your password.',
      );
    }
    return email;
  }

  // ------------------------------------------------- reading preferences (login pertama)

  /// true = pengguna baru yang belum mengisi/melewati layar Reading Preferences.
  /// Jika pengecekan gagal (mis. kolom belum ada karena SQL 05 belum dijalankan),
  /// hasilnya false supaya pengguna tidak terkunci.
  Future<bool> needsPreferencesSetup() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final row = await _client
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();
      return row != null && row['onboarding_completed'] == false;
    } catch (e) {
      debugPrint('needsPreferencesSetup check failed: $e');
      return false;
    }
  }

  // ====================================================== 2FA (TOTP, authenticator)

  /// Faktor TOTP terverifikasi menurut data sesi lokal (tanpa jaringan).
  Factor? get _localVerifiedTotp {
    final factors = currentUser?.factors;
    if (factors == null) return null;
    for (final factor in factors) {
      if (factor.factorType == FactorType.totp &&
          factor.status == FactorStatus.verified) {
        return factor;
      }
    }
    return null;
  }

  /// true = akun ini memakai 2FA (menurut sesi lokal).
  bool get hasMfaEnabled => _localVerifiedTotp != null;

  /// true = password sudah benar (AAL1) tetapi kode authenticator belum
  /// dimasukkan (AAL2). Selama true, aplikasi tidak boleh dibuka.
  bool get needsMfaChallenge {
    final aal = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    return aal.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
        aal.nextLevel == AuthenticatorAssuranceLevels.aal2;
  }

  /// Status terbaru dari server (dipakai layar pengaturan 2FA).
  Future<Factor?> fetchVerifiedTotpFactor() async {
    try {
      final result = await _client.auth.mfa.listFactors();
      return result.totp.isEmpty ? null : result.totp.first;
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Login / langkah tambahan reset & ganti password: kode 6 digit dari app.
  /// Berhasil = sesi naik ke AAL2.
  Future<void> verifyMfaCode(String code) async {
    final factorId = _localVerifiedTotp?.id ?? (await fetchVerifiedTotpFactor())?.id;
    if (factorId == null) {
      throw const AuthFlowException(
        AuthFailure.other,
        'Two-factor authentication is not set up for this account.',
      );
    }
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Mulai pemasangan: buang sisa percobaan lama, lalu minta QR + kunci baru.
  Future<MfaEnrollment> startMfaEnrollment() async {
    try {
      final existing = await _client.auth.mfa.listFactors();
      for (final factor in existing.all) {
        if (factor.status != FactorStatus.verified) {
          try {
            await _client.auth.mfa.unenroll(factor.id);
          } catch (e) {
            debugPrint('Removing stale factor failed: $e');
          }
        }
      }

      final enrollment = await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Intertwined',
        friendlyName: 'Intertwined ${DateTime.now().millisecondsSinceEpoch}',
      );
      final totp = enrollment.totp;
      if (totp == null) {
        throw const AuthFlowException(
          AuthFailure.unavailable,
          'Two-factor authentication is not available right now.',
        );
      }
      return MfaEnrollment(
        factorId: enrollment.id,
        secret: totp.secret,
        uri: totp.uri,
      );
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Kode pertama dari aplikasi membuktikan QR sudah terpindai: faktor aktif.
  Future<void> confirmMfaEnrollment({
    required String factorId,
    required String code,
  }) async {
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
    } catch (e) {
      throw AuthFlowException.from(e);
    }
  }

  /// Batalkan pemasangan yang belum selesai (best effort).
  Future<void> cancelMfaEnrollment(String factorId) async {
    try {
      await _client.auth.mfa.unenroll(factorId);
    } catch (e) {
      debugPrint('Cancel MFA enrollment failed: $e');
    }
  }

  /// Matikan 2FA. Server hanya mengizinkan dari sesi AAL2 (sudah lolos 2FA).
  Future<void> disableMfa() async {
    final factor = await fetchVerifiedTotpFactor();
    if (factor == null) return;
    try {
      await _client.auth.mfa.unenroll(factor.id);
    } catch (e) {
      throw AuthFlowException.from(e);
    }
    try {
      await _client.auth.refreshSession(); // sinkronkan faktor & level sesi
    } catch (e) {
      debugPrint('Refresh after disabling MFA failed: $e');
    }
  }

  // ============================================================== hapus akun

  /// Menghapus akun beserta semua datanya secara permanen.
  ///
  /// 1. password dicek ulang (klien sementara, sesi tidak berubah)
  /// 2. foto profil di Storage dihapus (Storage tidak ikut terhapus oleh SQL)
  /// 3. fungsi database `delete_my_account()` menghapus semua data lalu akun
  ///    (satu transaksi: gagal = tidak ada yang terhapus). Lihat sql/08.
  /// 4. sesi lokal dibersihkan -> root otomatis kembali ke layar login
  Future<void> deleteAccount({required String password}) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFlowException(
        AuthFailure.other,
        'You need to be signed in to delete your account.',
      );
    }

    await verifyCurrentPassword(password);

    try {
      await _client.storage.from('avatars').remove(['${user.id}/avatar']);
    } catch (e) {
      debugPrint('Removing avatar during account deletion failed: $e');
    }

    try {
      await _client.rpc('delete_my_account');
    } on PostgrestException catch (e) {
      throw _deleteFailure(e);
    } catch (e) {
      throw AuthFlowException.from(e);
    }

    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('Local sign out after account deletion failed: $e');
    }
  }

  AuthFlowException _deleteFailure(PostgrestException e) {
    final message = e.message.toLowerCase();
    if (e.code == '42501' || message.contains('two-factor')) {
      return const AuthFlowException(
        AuthFailure.mfaRequired,
        'Please sign in again, enter your authenticator code, then retry.',
      );
    }
    if (e.code == 'PGRST202' || message.contains('could not find the function')) {
      return const AuthFlowException(
        AuthFailure.unavailable,
        'Account deletion is not set up on the server yet. Please contact the Intertwined team.',
      );
    }
    debugPrint('delete_my_account failed: ${e.code} ${e.message}');
    return const AuthFlowException(
      AuthFailure.other,
      'Could not delete your account. Nothing was deleted, please try again.',
    );
  }
}
