import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/entities/user_entity.dart';

class MockProfileRepository implements ProfileRepository {
  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserEntity(
      id: userId,
      username: 'dummy_user',
      fullName: 'Dummy User',
      email: 'test@test.com',
      bio: 'A book lover from the dummy world.',
      avatarUrl: 'https://via.placeholder.com/150',
      favoriteGenres: ['Fantasy', 'Sci-Fi'],
      joinedDate: DateTime.now(),
    );
  }

  @override
  Future<void> updateProfile(String userId, {String? fullName, String? bio, List<String>? favoriteGenres}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Dummy update - do nothing
  }
}
