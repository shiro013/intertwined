class SupabaseConfig {
  static const String supabaseUrl = 'https://hagztbblhwyrufmbxscv.supabase.co';
  static const String supabaseKey =
      'sb_publishable_WBPeWJVdHQiLl1lgLNJuJA_iGPh9nNG';
  /// Jangan taruh API key di kode. Jalankan dengan:
  ///   flutter run --dart-define=GOOGLE_BOOKS_API_KEY=xxxxx
  /// Tanpa key, Google Books tetap jalan tetapi dengan kuota anonim yang kecil.
  static const String googleBooksApiKey =
      String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  /// Potongan query siap pakai ('' kalau key kosong).
  static String get googleBooksKeyParam =>
      googleBooksApiKey.isEmpty ? '' : '&key=$googleBooksApiKey';
}
