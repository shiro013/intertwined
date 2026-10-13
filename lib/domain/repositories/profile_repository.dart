import 'dart:typed_data';

import '../entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity?> getUserProfile(String userId);

  /// Hanya field yang diberi nilai (tidak null) yang diubah.
  /// [onboardingCompleted] sengaja hanya dikirim dari layar Reading Preferences.
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    List<String>? favoriteGenres,
    List<String>? favoriteAuthors,
    bool? onboardingCompleted,
  });

  /// Mengunggah foto profil ke Storage dan menyimpan URL-nya di profil.
  Future<String> uploadAvatar(String userId, Uint8List bytes, String contentType);

  /// Menghapus foto profil (file + URL di profil).
  Future<void> removeAvatar(String userId);
}
