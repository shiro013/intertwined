import '../../domain/entities/feed_activity_entity.dart';

abstract class FeedRepository {
  Future<List<FeedActivityEntity>> fetchFeed({bool followingOnly = false});
  Future<void> postActivity(String userId, String activityType, {String? bookId, String? contentId, String? preview});
  Future<void> followUser(String userId, String targetUserId);
  Future<void> unfollowUser(String userId, String targetUserId);
  Future<bool> isFollowing(String userId, String targetUserId);
}
