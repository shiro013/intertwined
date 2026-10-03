import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quote_repository.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  QuoteEntity _fromRow(Map<String, dynamic> item) {
    final book = item['books'] as Map<String, dynamic>?;
    final profile = item['profiles'] as Map<String, dynamic>?;
    return QuoteEntity(
      id: item['id'].toString(),
      userId: item['user_id'].toString(),
      bookId: item['book_id'].toString(),
      bookTitle: book?['title']?.toString() ?? 'Unknown Book',
      username: profile?['username']?.toString(),
      text: item['quote_text']?.toString() ?? '',
      pageNumber: (item['page_number'] as num?)?.toInt(),
      tags: (item['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<void> saveQuote(String userId, String bookId, String text, int pageNumber, List<String> tags) async {
    await _supabase.from('quotes').insert({
      'user_id': userId,
      'book_id': bookId,
      'quote_text': text,
      'page_number': pageNumber > 0 ? pageNumber : null,
      'tags': tags,
    });
  }

  @override
  Future<List<QuoteEntity>> fetchUserQuotes(String userId) async {
    final rows = await _supabase
        .from('quotes')
        .select('*, books(title)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<QuoteEntity>> fetchBookQuotes(String bookUuid) async {
    final rows = await _supabase
        .from('quotes')
        .select('*, books(title), profiles(username)')
        .eq('book_id', bookUuid)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<QuoteEntity>> searchQuotes(String query) async {
    final rows = await _supabase
        .from('quotes')
        .select('*, books(title)')
        .or('quote_text.ilike.%$query%,tags.cs.{$query}')
        .order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
    await _supabase.from('quotes').delete().eq('id', quoteId);
  }
}
