import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      final data = response as Map<String, dynamic>;
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
        favoriteGenres: (data['favorite_genres'] as List? ?? []).cast<String>(),
      );
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(String userId, {String? fullName, String? bio, List<String>? favoriteGenres}) async {
    await _client.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (favoriteGenres != null) 'favorite_genres': favoriteGenres,
    }).eq('id', userId);
  }
}
