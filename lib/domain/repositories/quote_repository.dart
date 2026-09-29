import '../entities/quote_entity.dart';

abstract class QuoteRepository {
  Future<void> saveQuote(String userId, String bookId, String text, int pageNumber, List<String> tags);
  Future<List<QuoteEntity>> fetchUserQuotes(String userId);
  Future<List<QuoteEntity>> searchQuotes(String query);
  Future<void> deleteQuote(String quoteId);
}
