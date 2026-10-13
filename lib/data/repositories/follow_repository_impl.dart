import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/follow_entities.dart';
import '../../domain/repositories/follow_repository.dart';

class FollowRepositoryImpl implements FollowRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _personColumns = 'id, username, full_name, avatar_url, bio';

  String? get _me => _client.auth.currentUser?.id;

  @override
  Future<bool> isFollowing(String targetUserId) async {
    final me = _me;
    if (me == null) return false;
    final row = await _client
        .from('follows')
        .select('follower_id')
        .match({'follower_id': me, 'following_id': targetUserId})
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> follow(String targetUserId) async {
    final me = _me;
    if (me == null) throw Exception('You need to be signed in.');
    if (me == targetUserId) throw Exception('You cannot follow yourself.');
    // PK (follower_id, following_id) -> aman kalau terpanggil dua kali.
    await _client.from('follows').upsert(
      {'follower_id': me, 'following_id': targetUserId},
      onConflict: 'follower_id,following_id',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<void> unfollow(String targetUserId) async {
    final me = _me;
    if (me == null) throw Exception('You need to be signed in.');
    await _client
        .from('follows')
        .delete()
        .match({'follower_id': me, 'following_id': targetUserId});
  }

  @override
  Future<ProfileStats> getStats(String userId) async {
    // Jalur utama: fungsi database (sql/06_follow_system.sql) yang menghitung
    // semuanya sekaligus, termasuk data yang tidak boleh dibaca langsung
    // oleh pengguna lain (reading_status, reviews).
    try {
      final result = await _client.rpc(
        'get_profile_stats',
        params: {'p_user_id': userId},
      );
      if (result is Map) {
        int n(String key) => (result[key] as num?)?.toInt() ?? 0;
        return ProfileStats(
          booksRead: n('books_read'),
          booksRated: n('books_rated'),
          quotesSaved: n('quotes_saved'),
          clubsJoined: n('clubs_joined'),
          followers: n('followers'),
          following: n('following'),
        );
      }
    } catch (e) {
      debugPrint('get_profile_stats unavailable, using fallback: $e');
    }

    // Cadangan kalau SQL 06 belum dijalankan: hanya angka yang pasti bisa dibaca.
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _client.from('follows').select('follower_id').eq('following_id', userId),
        _client.from('follows').select('following_id').eq('follower_id', userId),
        _client.from('quotes').select('id').eq('user_id', userId),
      ]);
      return ProfileStats(
        followers: results[0].length,
        following: results[1].length,
        quotesSaved: results[2].length,
      );
    } catch (e) {
      debugPrint('Profile stats fallback failed: $e');
      return const ProfileStats();
    }
  }

  @override
  Future<List<UserSummary>> getFollowers(String userId) async {
    final rows = await _client
        .from('follows')
        .select('created_at, person:profiles!follows_follower_id_fkey($_personColumns)')
        .eq('following_id', userId)
        .order('created_at', ascending: false)
        .limit(200);
    return _fromEmbedded(rows);
  }

  @override
  Future<List<UserSummary>> getFollowing(String userId) async {
    final rows = await _client
        .from('follows')
        .select('created_at, person:profiles!follows_following_id_fkey($_personColumns)')
        .eq('follower_id', userId)
        .order('created_at', ascending: false)
        .limit(200);
    return _fromEmbedded(rows);
  }

  @override
  Future<List<UserSummary>> searchUsers(String query) async {
    // Karakter ini merusak sintaks filter `or(...)` / pola ILIKE, jadi dibuang.
    final term = query.trim().replaceAll(RegExp(r'[,()"\\%_*]'), ' ').trim();
    if (term.length < 2) return [];

    var request = _client
        .from('profiles')
        .select(_personColumns)
        .or('username.ilike.%$term%,full_name.ilike.%$term%');

    final me = _me;
    if (me != null) request = request.neq('id', me);

    final rows = await request.order('username', ascending: true).limit(30);
    return rows.map(_summary).toList();
  }

  // ---------------------------------------------------------------- helpers

  UserSummary _summary(Map<String, dynamic> p) {
    return UserSummary(
      id: p['id'].toString(),
      username: p['username']?.toString() ?? 'Unknown',
      fullName: p['full_name']?.toString(),
      avatarUrl: p['avatar_url']?.toString(),
      bio: p['bio']?.toString(),
    );
  }

  List<UserSummary> _fromEmbedded(List<Map<String, dynamic>> rows) {
    final out = <UserSummary>[];
    for (final row in rows) {
      final person = row['person'];
      if (person is Map<String, dynamic>) out.add(_summary(person));
    }
    return out;
  }
}
