import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _avatarBucket = 'avatars';

  String _avatarPath(String userId) => '$userId/avatar';

  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return UserEntity(
        id: data['id'] as String,
        username: data['username'] as String,
        email: data['email'] as String? ?? '',
        fullName: data['full_name'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        bio: data['bio'] as String?,
        joinedDate: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : null,
        favoriteGenres: (data['favorite_genres'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        favoriteAuthors: (data['favorite_authors'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        // kolom baru; jika SQL 05 belum dijalankan dianggap sudah selesai (tidak mengganggu)
        onboardingCompleted: data['onboarding_completed'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    List<String>? favoriteGenres,
    List<String>? favoriteAuthors,
    bool? onboardingCompleted,
  }) async {
    await _client
        .from('profiles')
        .update({
          'full_name': ?fullName,
          'bio': ?bio,
          'favorite_genres': ?favoriteGenres,
          'favorite_authors': ?favoriteAuthors,
          'onboarding_completed': ?onboardingCompleted,
        })
        .eq('id', userId);
  }

  @override
  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String contentType,
  ) async {
    final path = _avatarPath(userId);
    final storage = _client.storage.from(_avatarBucket);

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    // Path sama dipakai terus, jadi tambahkan penanda versi agar gambar lama
    // tidak tertahan di cache browser/CDN.
    final url =
        '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }

  @override
  Future<void> removeAvatar(String userId) async {
    try {
      await _client.storage.from(_avatarBucket).remove([_avatarPath(userId)]);
    } catch (e) {
      // file mungkin sudah tidak ada; yang penting URL di profil dibersihkan
      debugPrint('Remove avatar file failed: $e');
    }
    await _client
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', userId);
  }
}
