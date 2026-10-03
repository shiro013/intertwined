import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/community_entities.dart';

/// Hitung like + apakah user saat ini sudah like, untuk banyak target sekaligus
/// (satu query). `likes` bersifat polymorphic (target_type + target_id) sehingga
/// tidak bisa di-embed lewat relasi PostgREST.
///
/// Jika query gagal (mis. RLS), kembalikan map kosong supaya halaman tetap tampil.
Future<Map<String, LikeInfo>> fetchLikeInfo(
  SupabaseClient client,
  String targetType,
  List<String> ids,
) async {
  if (ids.isEmpty) return {};
  try {
    final me = client.auth.currentUser?.id;
    final rows = await client
        .from('likes')
        .select('target_id, user_id')
        .eq('target_type', targetType)
        .inFilter('target_id', ids);

    final counts = <String, int>{};
    final mine = <String>{};
    for (final row in rows) {
      final targetId = row['target_id'].toString();
      counts[targetId] = (counts[targetId] ?? 0) + 1;
      if (me != null && row['user_id'].toString() == me) mine.add(targetId);
    }
    return {
      for (final id in ids)
        id: LikeInfo(count: counts[id] ?? 0, likedByMe: mine.contains(id)),
    };
  } catch (e) {
    debugPrint('fetchLikeInfo($targetType) error: $e');
    return {};
  }
}
