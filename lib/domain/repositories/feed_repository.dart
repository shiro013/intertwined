import '../../domain/entities/feed_activity_entity.dart';

abstract class FeedRepository {
  /// Feed (FR-20): aktivitas Anda dan sesama anggota klub yang Anda ikuti
  /// (kutipan, review, repost) + diskusi di klub-klub tersebut, terbaru dulu.
  Future<List<FeedActivityEntity>> fetchFeed({int limit = 40});

  Future<void> postActivity(String userId, String activityType, {String? bookId, String? contentId, String? preview});

  /// Bagikan kutipan milik sendiri ke feed (FR-19).
  /// Mengembalikan false jika kutipan ini sudah pernah dibagikan.
  Future<bool> shareQuote({required String quoteId, String? bookUuid, required String preview});

  /// Repost kutipan/review orang lain ke feed pribadi (FR-21). [type] = 'quote' atau 'review'.
  /// Mengembalikan false jika sudah pernah di-repost.
  Future<bool> repost({required String type, required String originalId, String? bookUuid, required String preview});

  Future<void> followUser(String userId, String targetUserId);
  Future<void> unfollowUser(String userId, String targetUserId);
  Future<bool> isFollowing(String userId, String targetUserId);
}
