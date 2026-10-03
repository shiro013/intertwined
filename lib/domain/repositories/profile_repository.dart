import '../entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity?> getUserProfile(String userId);
  Future<void> updateProfile(String userId, {String? fullName, String? bio, List<String>? favoriteGenres});
}
