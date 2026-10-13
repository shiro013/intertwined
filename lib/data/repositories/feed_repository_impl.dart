import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/community_entities.dart';
import '../../domain/entities/feed_activity_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import 'likes_helper.dart';

class FeedRepositoryImpl implements FeedRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _activitySelect =
      '*, profiles(username, avatar_url), books(title, cover_url, external_id)';
  static const String _discussionSelect =
      '*, profiles(username, avatar_url), groups(name), comments(count)';

  @override
  Future<List<FeedActivityEntity>> fetchFeed({int limit = 40}) async {
    final me = _supabase.auth.currentUser;
    if (me == null) return [];

    // 1) klub yang saya ikuti
    final myGroupRows =
        await _supabase.from('group_members').select('group_id').eq('user_id', me.id);
    final groupIds = myGroupRows.map((r) => r['group_id'].toString()).toList();

    // 2) penulis feed = saya + sesama anggota klub saya + orang yang saya follow
    final authorIds = <String>{me.id};
    if (groupIds.isNotEmpty) {
      try {
        final memberRows = await _supabase
            .from('group_members')
            .select('user_id')
            .inFilter('group_id', groupIds)
            .limit(1000);
        authorIds.addAll(memberRows.map((r) => r['user_id'].toString()));
      } catch (e) {
        debugPrint('Feed: loading club members failed: $e');
      }
    }

        // 2b) orang yang saya ikuti (follow) ikut tampil di feed
    try {
      final followRows = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', me.id)
          .limit(1000);
      authorIds.addAll(followRows.map((r) => r['following_id'].toString()));
    } catch (e) {
      debugPrint('Feed: loading followed users failed: $e');
    }

    // 3) aktivitas (kutipan, review, repost)
    final activityRows = await _supabase
        .from('feed_activities')
        .select(_activitySelect)
        .inFilter('user_id', authorIds.toList())
        .order('created_at', ascending: false)
        .limit(limit);

    final originalAuthors = await _originalAuthors(activityRows);
    final items = <FeedActivityEntity>[
      for (final row in activityRows) _activityFromRow(row, originalAuthors),
    ];

    // 4) diskusi di klub saya
    items.addAll(await _discussionItems(groupIds, limit: 20));

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  FeedActivityEntity _activityFromRow(
    Map<String, dynamic> row,
    Map<String, String> originalAuthors,
  ) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final book = row['books'] as Map<String, dynamic>?;
    final originalId = row['original_content_id']?.toString();

    return FeedActivityEntity(
      id: row['id'].toString(),
      userId: row['user_id'].toString(),
      username: profile?['username']?.toString() ?? 'Unknown',
      avatarUrl: profile?['avatar_url']?.toString(),
      activityType: row['activity_type'].toString(),
      bookId: row['book_id']?.toString(),
      bookExternalId: book?['external_id']?.toString(),
      bookTitle: book?['title']?.toString(),
      bookCoverUrl: book?['cover_url']?.toString(),
      originalContentId: originalId,
      contentPreview: row['content_preview']?.toString(),
      originalAuthor: originalId == null ? null : originalAuthors[originalId],
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Untuk repost: cari username penulis kutipan/review aslinya.
  Future<Map<String, String>> _originalAuthors(List<Map<String, dynamic>> activityRows) async {
    final quoteIds = <String>{};
    final reviewIds = <String>{};
    for (final row in activityRows) {
      final id = row['original_content_id']?.toString();
      if (id == null) continue;
      final type = row['activity_type']?.toString() ?? '';
      if (type == 'repost_quote') {
        quoteIds.add(id);
      } else if (type == 'repost_review') {
        reviewIds.add(id);
      }
    }

    final result = <String, String>{};
    Future<void> load(String table, Set<String> ids) async {
      if (ids.isEmpty) return;
      try {
        final rows = await _supabase
            .from(table)
            .select('id, profiles(username)')
            .inFilter('id', ids.toList());
        for (final row in rows) {
          final name = (row['profiles'] as Map<String, dynamic>?)?['username']?.toString();
          if (name != null) result[row['id'].toString()] = name;
        }
      } catch (e) {
        debugPrint('Feed: loading original authors from $table failed: $e');
      }
    }

    await Future.wait([load('quotes', quoteIds), load('reviews', reviewIds)]);
    return result;
  }

  int _embeddedCount(dynamic embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map) return (first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<List<FeedActivityEntity>> _discussionItems(List<String> groupIds, {required int limit}) async {
    if (groupIds.isEmpty) return [];
    try {
      final rows = await _supabase
          .from('discussions')
          .select(_discussionSelect)
          .inFilter('group_id', groupIds)
          .order('created_at', ascending: false)
          .limit(limit);

      final likes = await fetchLikeInfo(
        _supabase,
        'discussion',
        rows.map((r) => r['id'].toString()).toList(),
      );

      return rows.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        final group = row['groups'] as Map<String, dynamic>?;
        final id = row['id'].toString();
        final like = likes[id];
        final createdAt =
            DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now();

        final discussion = CommunityDiscussion(
          id: id,
          groupId: row['group_id'].toString(),
          groupName: group?['name']?.toString(),
          userId: row['user_id'].toString(),
          username: profile?['username']?.toString() ?? 'Unknown',
          content: row['content']?.toString() ?? '',
          createdAt: createdAt,
          replyCount: _embeddedCount(row['comments']),
          likeCount: like?.count ?? 0,
          likedByMe: like?.likedByMe ?? false,
        );

        return FeedActivityEntity(
          id: 'discussion-$id', // supaya tidak bentrok dengan id baris feed_activities
          userId: discussion.userId,
          username: discussion.username,
          avatarUrl: profile?['avatar_url']?.toString(),
          activityType: 'post_discussion',
          contentPreview: discussion.content,
          groupName: discussion.groupName,
          discussion: discussion,
          createdAt: createdAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('Feed: loading discussions failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------- actions

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

  /// Satu pengguna hanya boleh membagikan/me-repost satu konten satu kali.
  Future<bool> _insertOnce({
    required String type,
    required String originalId,
    String? bookUuid,
    required String preview,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kamu harus login dulu');

    final existing = await _supabase
        .from('feed_activities')
        .select('id')
        .eq('user_id', user.id)
        .eq('activity_type', type)
        .eq('original_content_id', originalId)
        .limit(1)
        .maybeSingle();
    if (existing != null) return false;

    await _supabase.from('feed_activities').insert({
      'user_id': user.id,
      'activity_type': type,
      'book_id': bookUuid,
      'original_content_id': originalId,
      'content_preview': preview,
    });
    return true;
  }

  @override
  Future<bool> shareQuote({required String quoteId, String? bookUuid, required String preview}) {
    return _insertOnce(
      type: 'share_quote',
      originalId: quoteId,
      bookUuid: bookUuid,
      preview: preview,
    );
  }

  @override
  Future<bool> repost({
    required String type,
    required String originalId,
    String? bookUuid,
    required String preview,
  }) {
    if (type != 'quote' && type != 'review') {
      throw ArgumentError('Only quotes and reviews can be reposted');
    }
    return _insertOnce(
      type: 'repost_$type',
      originalId: originalId,
      bookUuid: bookUuid,
      preview: preview,
    );
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
