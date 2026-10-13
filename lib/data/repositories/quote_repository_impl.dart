import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quote_repository.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _select = '*, books(title, external_id), profiles(username)';

  QuoteEntity _fromRow(Map<String, dynamic> item) {
    final book = item['books'] as Map<String, dynamic>?;
    final profile = item['profiles'] as Map<String, dynamic>?;
    return QuoteEntity(
      id: item['id'].toString(),
      userId: item['user_id'].toString(),
      bookId: item['book_id'].toString(),
      bookTitle: book?['title']?.toString() ?? 'Unknown Book',
      bookExternalId: book?['external_id']?.toString(),
      username: profile?['username']?.toString(),
      text: item['quote_text']?.toString() ?? '',
      pageNumber: (item['page_number'] as num?)?.toInt(),
      tags: (item['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<String> saveQuote(String userId, String bookId, String text, int pageNumber, List<String> tags) async {
    final row = await _supabase
        .from('quotes')
        .insert({
          'user_id': userId,
          'book_id': bookId,
          'quote_text': text,
          'page_number': pageNumber > 0 ? pageNumber : null,
          'tags': tags,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  @override
  Future<List<QuoteEntity>> fetchUserQuotes(String userId) async {
    final rows = await _supabase
        .from('quotes')
        .select(_select)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<QuoteEntity>> fetchBookQuotes(String bookUuid) async {
    final rows = await _supabase
        .from('quotes')
        .select(_select)
        .eq('book_id', bookUuid)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(_fromRow).toList();
  }

  /// Cari kutipan semua pengguna berdasarkan KATA KUNCI (isi kutipan), NAMA BUKU,
  /// atau TAG (FR-12). Tiga pencarian dijalankan bersamaan lalu digabung tanpa duplikat.
  @override
  Future<List<QuoteEntity>> searchQuotes(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    // "%" dan "_" adalah karakter khusus di ILIKE; jadikan huruf biasa.
    final likeTerm = term
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');

    // Untuk filter tag, koma/kurung/kurawal/kutip akan merusak sintaks query.
    final tagTerm = term.replaceAll(RegExp(r'[,(){}"\\]'), '').trim();

    final Future<List<Map<String, dynamic>>> byText = _supabase
        .from('quotes')
        .select(_select)
        .ilike('quote_text', '%$likeTerm%')
        .order('created_at', ascending: false)
        .limit(30);

    // Pencarian tambahan: kegagalannya tidak boleh menggagalkan pencarian utama.
    final Future<List<Map<String, dynamic>>> byTag = tagTerm.isEmpty
        ? Future.value(<Map<String, dynamic>>[])
        : _supabase
            .from('quotes')
            .select(_select)
            .or('tags.cs.{$tagTerm},tags.cs.{${tagTerm.toLowerCase()}}')
            .order('created_at', ascending: false)
            .limit(30);

    final results = await Future.wait<List<Map<String, dynamic>>>([
      byText,
      byTag.catchError((Object e) {
        debugPrint('Quote tag search failed: $e');
        return <Map<String, dynamic>>[];
      }),
      _quotesForBookTitle(likeTerm).catchError((Object e) {
        debugPrint('Quote book-title search failed: $e');
        return <Map<String, dynamic>>[];
      }),
    ]);

    final seen = <String>{};
    final merged = <QuoteEntity>[];
    for (final rows in results) {
      for (final row in rows) {
        if (seen.add(row['id'].toString())) merged.add(_fromRow(row));
      }
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged.take(50).toList();
  }

  Future<List<Map<String, dynamic>>> _quotesForBookTitle(String likeTerm) async {
    final books = await _supabase
        .from('books')
        .select('id')
        .ilike('title', '%$likeTerm%')
        .limit(20);
    final ids = books.map((b) => b['id'].toString()).toList();
    if (ids.isEmpty) return [];

    return await _supabase
        .from('quotes')
        .select(_select)
        .inFilter('book_id', ids)
        .order('created_at', ascending: false)
        .limit(30);
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
        await _supabase.from('quotes').delete().eq('id', quoteId);

    // Best effort: buang item feed (share/repost) yang menunjuk ke kutipan ini,
    // supaya feed tidak menampilkan kutipan yang sudah dihapus.
    try {
      await _supabase
          .from('feed_activities')
          .delete()
          .eq('original_content_id', quoteId)
          .inFilter('activity_type', ['share_quote', 'repost_quote']);
    } catch (e) {
      debugPrint('Cleaning feed items of deleted quote failed: $e');
    }
  }
}
