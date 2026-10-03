/// Validasi input untuk form auth. Ini hanya lapisan UX di sisi aplikasi;
/// aturan yang BENAR-BENAR mengikat harus diset juga di server
/// (Supabase Dashboard -> Authentication -> Providers -> Email).
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');

  static const Set<String> _commonPasswords = {
    'password', 'password1', 'password123', '12345678', '123456789',
    '1234567890', 'qwertyui', 'qwerty123', 'iloveyou', 'abc12345',
    'letmein1', 'admin123', 'welcome1', '11111111', 'asdfghjk',
  };

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// 3-20 karakter: huruf, angka, "_" atau ".". Tidak boleh mengandung "@"
  /// karena "@" dipakai untuk membedakan email dari username saat login.
  static String? username(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Choose a username';
    if (!_usernameRegex.hasMatch(v)) {
      return 'Use 3-20 characters: letters, numbers, "_" or "."';
    }
    return null;
  }

  static String? password(String? value, {String? username}) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (v.length > 72) return 'Use at most 72 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include at least one letter and one number';
    }
    if (_commonPasswords.contains(v.toLowerCase())) {
      return 'That password is too common';
    }
    final u = (username ?? '').trim().toLowerCase();
    if (u.length >= 3 && v.toLowerCase().contains(u)) {
      return 'Your password should not contain your username';
    }
    return null;
  }

  /// 0 (kosong) .. 4 (kuat)
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    if (_commonPasswords.contains(value.toLowerCase())) return 1;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value) && RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  static bool looksLikeEmail(String identifier) => identifier.contains('@');

  /// "budi.santoso@gmail.com" -> "b***@gmail.com"
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return email;
    return '${email[0]}***${email.substring(at)}';
  }
}
