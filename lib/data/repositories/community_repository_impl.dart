import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_entities.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<CommunityGroup>> fetchGroups() async {
    try {
      final response = await _supabase
          .from('groups')
          .select('*, books(cover_url)');

      final data = response as List;
      return data.map((group) {
        final bookData = group['books'] as Map<String, dynamic>?;
        return CommunityGroup(
          id: group['id'],
          name: group['name'],
          description: group['description'] ?? '',
          coverUrl: bookData?['cover_url'] ?? 'https://via.placeholder.com/200x300',
          memberCount: 0, // Will need a join or count query to implement correctly
          relatedBookId: group['book_id'],
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> joinGroup(String userId, String groupId) async {
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
      'role': 'member',
    });
  }

  @override
  Future<void> leaveGroup(String userId, String groupId) async {
    await _supabase
        .from('group_members')
        .delete()
        .match({'group_id': groupId, 'user_id': userId});
  }

  @override
  Future<void> toggleLike(String userId, String targetId, String targetType) async {
    final existing = await _supabase
        .from('likes')
        .select()
        .match({'user_id': userId, 'target_id': targetId, 'target_type': targetType})
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('likes').insert({
        'user_id': userId,
        'target_id': targetId,
        'target_type': targetType,
      });
    } else {
      await _supabase
          .from('likes')
          .delete()
          .match({'user_id': userId, 'target_id': targetId, 'target_type': targetType});
    }
  }

  @override
  Future<bool> hasLiked(String userId, String targetId, String targetType) async {
    final response = await _supabase
        .from('likes')
        .select()
        .match({'user_id': userId, 'target_id': targetId, 'target_type': targetType})
        .maybeSingle();
    return response != null;
  }

  @override
  Future<void> createDiscussion(String userId, String groupId, String content) async {
    await _supabase.from('discussions').insert({
      'group_id': groupId,
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<CommunityDiscussion>> fetchDiscussions(String groupId) async {
    try {
      final response = await _supabase
          .from('discussions')
          .select('*, profiles(username)')
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((disc) {
        final profile = disc['profiles'] as Map<String, dynamic>?;
        return CommunityDiscussion(
          id: disc['id'],
          groupId: disc['group_id'],
          userId: disc['user_id'],
          username: profile?['username'] ?? 'Unknown',
          content: disc['content'],
          createdAt: DateTime.parse(disc['created_at']),
          replyCount: 0, // Logic to count comments needed
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CommunityComment>> fetchComments(String discussionId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(username)')
          .eq('discussion_id', discussionId)
          .order('created_at', ascending: true);

      final data = response as List;
      return data.map((comment) {
        final profile = comment['profiles'] as Map<String, dynamic>?;
        return CommunityComment(
          id: comment['id'],
          discussionId: comment['discussion_id'],
          userId: comment['user_id'],
          username: profile?['username'] ?? 'Unknown',
          content: comment['content'],
          parentCommentId: comment['parent_comment_id'],
          createdAt: DateTime.parse(comment['created_at']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> postComment(String userId, String discussionId, String content, {String? parentCommentId}) async {
    await _supabase.from('comments').insert({
      'discussion_id': discussionId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<CommunityDiscussion>> fetchRecentDiscussions() async {
    try {
      final response = await _supabase
          .from('discussions')
          .select('*, profiles(username)')
          .order('created_at', ascending: false)
          .limit(20);

      final data = response as List;
      return data.map((disc) {
        final profile = disc['profiles'] as Map<String, dynamic>?;
        return CommunityDiscussion(
          id: disc['id'],
          groupId: disc['group_id'],
          userId: disc['user_id'],
          username: profile?['username'] ?? 'Unknown',
          content: disc['content'],
          createdAt: DateTime.parse(disc['created_at']),
          replyCount: 0,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
