import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/feed_activity_entity.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<FeedActivityEntity>> fetchFeed({bool followingOnly = false}) async {
    try {
      final currentUser = _supabase.auth.currentUser;

      var query = _supabase
          .from('feed_activities')
          .select('*, profiles(username, avatar_url), books(title, cover_url)');

      if (followingOnly && currentUser != null) {
        final followsResponse = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUser.id);

        final followingIds = (followsResponse as List).map((f) => f['following_id']).toList();

        if (followingIds.isEmpty) return [];

        query = query.filter('profiles(id)', 'in', followingIds.join(','));
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(50);

      final data = response as List;
      return data.map((item) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final book = item['books'] as Map<String, dynamic>?;

        return FeedActivityEntity(
          id: item['id'],
          userId: item['user_id'],
          username: profile?['username'] ?? 'Unknown',
          avatarUrl: profile?['avatar_url'],
          activityType: item['activity_type'],
          bookId: item['book_id'],
          bookTitle: book?['title'],
          bookCoverUrl: book?['cover_url'],
          originalContentId: item['original_content_id'],
          contentPreview: item['content_preview'],
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> postActivity(String userId, String activityType, {String? bookId, String? contentId, String? preview}) async {
    await _supabase.from('feed_activities').insert({
      'user_id': userId,
      'activity_type': activityType,
      'book_id': bookId,
      'original_content_id': contentId,
      'content_preview': preview,
    });
  }

  @override
  Future<void> followUser(String userId, String targetUserId) async {
    await _supabase.from('follows').insert({
      'follower_id': userId,
      'following_id': targetUserId,
    });
  }

  @override
  Future<void> unfollowUser(String userId, String targetUserId) async {
    await _supabase
        .from('follows')
        .delete()
        .match({'follower_id': userId, 'following_id': targetUserId});
  }

  @override
  Future<bool> isFollowing(String userId, String targetUserId) async {
    final response = await _supabase
        .from('follows')
        .select()
        .match({'follower_id': userId, 'following_id': targetUserId})
        .maybeSingle();
    return response != null;
  }
}
