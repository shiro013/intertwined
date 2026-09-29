import '../entities/community_entities.dart';

abstract class CommunityRepository {
  Future<List<CommunityGroup>> fetchGroups();
  Future<void> joinGroup(String userId, String groupId);
  Future<void> leaveGroup(String userId, String groupId);
  Future<void> createDiscussion(String userId, String groupId, String content);
  Future<List<CommunityDiscussion>> fetchDiscussions(String groupId);
  Future<List<CommunityComment>> fetchComments(String discussionId);
  Future<void> postComment(String userId, String discussionId, String content, {String? parentCommentId});
  Future<List<CommunityDiscussion>> fetchRecentDiscussions();
  Future<void> toggleLike(String userId, String targetId, String targetType);
  Future<bool> hasLiked(String userId, String targetId, String targetType);
}
