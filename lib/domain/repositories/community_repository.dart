import '../entities/community_entities.dart';

/// Dilempar saat nama klub sudah dipakai klub lain.
class ClubNameTakenException implements Exception {
  const ClubNameTakenException();

  @override
  String toString() => 'A club with this name already exists. Please choose another name.';
}

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

  /// Buat klub berdasarkan TOPIK (tanpa buku). Pembuat otomatis jadi admin.
  /// Melempar [ClubNameTakenException] jika namanya sudah dipakai.
  Future<CommunityGroup> createGroup({required String name, String description = ''});

  Future<void> joinGroup(String userId, String groupId, {String role = 'member'});
  Future<void> leaveGroup(String userId, String groupId);
  Future<void> createDiscussion(String userId, String groupId, String content);
  Future<List<CommunityDiscussion>> fetchDiscussions(String groupId);

  /// Satu diskusi (lengkap dengan jumlah like/balasan), atau null jika sudah dihapus.
  Future<CommunityDiscussion?> fetchDiscussion(String discussionId);

  /// Satu klub berdasarkan id, atau null jika tidak ada.
  Future<CommunityGroup?> fetchGroup(String groupId);
  Future<List<CommunityComment>> fetchComments(String discussionId);
  Future<void> postComment(String userId, String discussionId, String content, {String? parentCommentId});
  /// Diskusi terbaru MILIK [userId] saja (bukan semua pengguna).
  Future<List<CommunityDiscussion>> fetchRecentDiscussions(String userId);

  Future<void> toggleLike(String userId, String targetId, String targetType);

  /// Set eksplisit (idempotent) -> aman untuk optimistic UI.
  Future<void> setLike(String userId, String targetId, String targetType, bool liked);
  Future<bool> hasLiked(String userId, String targetId, String targetType);
}
