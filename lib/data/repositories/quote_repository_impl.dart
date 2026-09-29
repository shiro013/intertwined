import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quote_repository.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> saveQuote(String userId, String bookId, String text, int pageNumber, List<String> tags) async {
    await _supabase.from('quotes').insert({
      'user_id': userId,
      'book_id': bookId,
      'quote_text': text,
      'page_number': pageNumber,
      'tags': tags,
    });
  }

  @override
  Future<List<QuoteEntity>> fetchUserQuotes(String userId) async {
    try {
      final response = await _supabase
          .from('quotes')
          .select('*, books(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((item) {
        final book = item['books'] as Map<String, dynamic>?;
        return QuoteEntity(
          id: item['id'],
          userId: item['user_id'],
          bookId: item['book_id'],
          bookTitle: book?['title'] ?? 'Unknown Book',
          text: item['quote_text'],
          pageNumber: item['page_number'],
          tags: (item['tags'] as List? ?? []).cast<String>(),
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuoteEntity>> searchQuotes(String query) async {
    try {
      // Search in text or tags using Supabase ILIKE or text search
      final response = await _supabase
          .from('quotes')
          .select('*, books(title)')
          .or('quote_text.ilike.%$query%,tags.cs={$query}')
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((item) {
        final book = item['books'] as Map<String, dynamic>?;
        return QuoteEntity(
          id: item['id'],
          userId: item['user_id'],
          bookId: item['book_id'],
          bookTitle: book?['title'] ?? 'Unknown Book',
          text: item['quote_text'],
          pageNumber: item['page_number'],
          tags: (item['tags'] as List? ?? []).cast<String>(),
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
    await _supabase.from('quotes').delete().eq('id', quoteId);
  }
}
