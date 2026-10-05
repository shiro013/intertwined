import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/community_entities.dart';
import '../../domain/repositories/community_repository.dart';
import '../models/book_model.dart';
import 'likes_helper.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // `group_members(count)` / `comments(count)` = jumlah baris relasi (PostgREST embedded count)
  static const String _groupSelect = '*, books(cover_url), group_members(count)';
  static const String _discussionSelect =
      '*, profiles(username), groups(name), comments(count)';

  /// Bentuk hasil embedded count: `[{count: 3}]`
  int _embeddedCount(dynamic embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map) return (first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  CommunityGroup _groupFromRow(Map<String, dynamic> row) {
    final book = row['books'] as Map<String, dynamic>?;
    return CommunityGroup(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? 'Untitled club',
      description: row['description']?.toString() ?? '',
      coverUrl: BookModel.normalizeCoverUrl(book?['cover_url']?.toString()),
      memberCount: _embeddedCount(row['group_members']),
      relatedBookId: row['book_id']?.toString(),
    );
  }

  CommunityDiscussion _discussionFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final group = row['groups'] as Map<String, dynamic>?;
    return CommunityDiscussion(
      id: row['id'].toString(),
      groupId: row['group_id'].toString(),
      groupName: group?['name']?.toString(),
      userId: row['user_id'].toString(),
      username: profile?['username']?.toString() ?? 'Unknown',
      content: row['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      replyCount: _embeddedCount(row['comments']),
    );
  }

  Future<List<CommunityDiscussion>> _withLikes(List<CommunityDiscussion> items) async {
    final likes = await fetchLikeInfo(
      _supabase,
      'discussion',
      items.map((d) => d.id).toList(),
    );
    return items.map((d) {
      final like = likes[d.id];
      if (like == null) return d;
      return d.copyWith(likeCount: like.count, likedByMe: like.likedByMe);
    }).toList();
  }

  // ------------------------------------------------------------------ groups

  @override
  Future<List<CommunityGroup>> fetchGroups() async {
    final rows = await _supabase
        .from('groups')
        .select(_groupSelect)
        .order('created_at', ascending: false);

    final groups = rows.map(_groupFromRow).toList();
    // klub paling ramai tampil duluan
    groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return groups;
  }

  @override
  Future<Set<String>> fetchJoinedGroupIds(String userId) async {
    final rows = await _supabase
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    return rows.map((r) => r['group_id'].toString()).toSet();
  }

  @override
  Future<CommunityGroup?> findGroupForBook(String bookUuid) async {
    final row = await _supabase
        .from('groups')
        .select(_groupSelect)
        .eq('book_id', bookUuid)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : _groupFromRow(row);
  }

  @override
  Future<CommunityGroup> ensureGroupForBook({
    required String bookUuid,
    required String bookTitle,
  }) async {
    final existing = await findGroupForBook(bookUuid);
    if (existing != null) return existing;

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kamu harus login dulu');

    final inserted = await _supabase
        .from('groups')
        .insert({
          'name': '$bookTitle Club',
          'description': 'Talk about "$bookTitle" with fellow readers.',
          'book_id': bookUuid,
          'created_by': user.id,
        })
        .select(_groupSelect)
        .single();

    // pembuat otomatis jadi admin
    await joinGroup(user.id, inserted['id'].toString(), role: 'admin');
    return _groupFromRow(inserted).copyWith(memberCount: 1);
  }

  @override
  Future<void> joinGroup(String userId, String groupId, {String role = 'member'}) async {
    // PK (group_id, user_id) -> join dua kali tidak lagi error, cukup diabaikan.
    await _supabase.from('group_members').upsert(
      {
        'group_id': groupId,
        'user_id': userId,
        'role': role,
      },
      onConflict: 'group_id,user_id',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<void> leaveGroup(String userId, String groupId) async {
    await _supabase
        .from('group_members')
        .delete()
        .match({'group_id': groupId, 'user_id': userId});
  }

  // ------------------------------------------------------------------- likes

  @override
  Future<void> toggleLike(String userId, String targetId, String targetType) async {
    final liked = await hasLiked(userId, targetId, targetType);
    await setLike(userId, targetId, targetType, !liked);
  }

  @override
  Future<void> setLike(String userId, String targetId, String targetType, bool liked) async {
    if (liked) {
      // PK (user_id, target_id, target_type) -> aman kalau terpanggil dua kali
      await _supabase.from('likes').upsert(
        {
          'user_id': userId,
          'target_id': targetId,
          'target_type': targetType,
        },
        onConflict: 'user_id,target_id,target_type',
        ignoreDuplicates: true,
      );
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
        .select('user_id')
        .match({'user_id': userId, 'target_id': targetId, 'target_type': targetType})
        .limit(1)
        .maybeSingle();
    return response != null;
  }

  // -------------------------------------------------------------- discussions

  @override
  Future<void> createDiscussion(String userId, String groupId, String content) async {
    await _supabase.from('discussions').insert({
      'group_id': groupId,
      'user_id': userId,
      'content': content,
    });
  }

  @override
  Future<List<CommunityDiscussion>> fetchDiscussions(String groupId) async {
    final rows = await _supabase
        .from('discussions')
        .select(_discussionSelect)
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return _withLikes(rows.map(_discussionFromRow).toList());
  }

  @override
  Future<List<CommunityDiscussion>> fetchRecentDiscussions(String userId) async {
    final rows = await _supabase
        .from('discussions')
        .select(_discussionSelect)
        .eq('user_id', userId) // hanya postingan user ini
        .order('created_at', ascending: false)
        .limit(20);
    return _withLikes(rows.map(_discussionFromRow).toList());
  }

  // ---------------------------------------------------------------- comments

  @override
  Future<List<CommunityComment>> fetchComments(String discussionId) async {
    final rows = await _supabase
        .from('comments')
        .select('*, profiles(username)')
        .eq('discussion_id', discussionId)
        .order('created_at', ascending: true);

    return rows.map((comment) {
      final profile = comment['profiles'] as Map<String, dynamic>?;
      return CommunityComment(
        id: comment['id'].toString(),
        discussionId: comment['discussion_id'].toString(),
        userId: comment['user_id'].toString(),
        username: profile?['username']?.toString() ?? 'Unknown',
        content: comment['content']?.toString() ?? '',
        parentCommentId: comment['parent_comment_id']?.toString(),
        createdAt: DateTime.tryParse(comment['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> postComment(
    String userId,
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    await _supabase.from('comments').insert({
      'discussion_id': discussionId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
    });
  }
}
