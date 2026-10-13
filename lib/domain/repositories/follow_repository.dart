import '../entities/follow_entities.dart';

abstract class FollowRepository {
  /// Apakah pengguna yang sedang login mengikuti [targetUserId].
  Future<bool> isFollowing(String targetUserId);

  /// Idempotent: mengikuti dua kali tidak error.
  Future<void> follow(String targetUserId);

  Future<void> unfollow(String targetUserId);

  /// Angka profil [userId]. Tidak pernah melempar: kegagalan memberi angka 0.
  Future<ProfileStats> getStats(String userId);

  /// Orang yang mengikuti [userId].
  Future<List<UserSummary>> getFollowers(String userId);

  /// Orang yang diikuti [userId].
  Future<List<UserSummary>> getFollowing(String userId);

  /// Cari pengguna lain lewat username / nama lengkap.
  Future<List<UserSummary>> searchUsers(String query);
}
