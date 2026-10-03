import '../entities/community_entities.dart';

abstract class CommunityRepository {
  Future<List<CommunityGroup>> fetchGroups();
  Future<Set<String>> fetchJoinedGroupIds(String userId);

  /// Cari grup untuk sebuah buku (bookUuid = uuid tabel books). null jika belum ada.
  Future<CommunityGroup?> findGroupForBook(String bookUuid);

  /// Cari grup buku; kalau belum ada, buat otomatis (pembuat jadi admin).
  Future<CommunityGroup> ensureGroupForBook({
    required String bookUuid,
    required String bookTitle,
  });

  Future<void> joinGroup(String userId, String groupId, {String role = 'member'});
  Future<void> leaveGroup(String userId, String groupId);
  Future<void> createDiscussion(String userId, String groupId, String content);
  Future<List<CommunityDiscussion>> fetchDiscussions(String groupId);
  Future<List<CommunityComment>> fetchComments(String discussionId);
  Future<void> postComment(String userId, String discussionId, String content, {String? parentCommentId});
  Future<List<CommunityDiscussion>> fetchRecentDiscussions();

  Future<void> toggleLike(String userId, String targetId, String targetType);

  /// Set eksplisit (idempotent) -> aman untuk optimistic UI.
  Future<void> setLike(String userId, String targetId, String targetType, bool liked);
  Future<bool> hasLiked(String userId, String targetId, String targetType);
}
