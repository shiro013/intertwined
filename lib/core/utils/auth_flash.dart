/// Pesan satu-kali yang harus tampil di AuthScreen setelah seluruh pohon widget
/// di-reset (mis. setelah reset password -> sign out -> layar login baru).
class AuthFlash {
  AuthFlash._();

  static String? _message;

  static void set(String message) => _message = message;

  /// Ambil lalu hapus, supaya hanya tampil sekali.
  static String? take() {
    final m = _message;
    _message = null;
    return m;
  }
}
