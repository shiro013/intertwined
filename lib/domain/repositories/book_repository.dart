import '../entities/book_entity.dart';
import '../entities/user_book_interaction_entity.dart';

abstract class BookRepository {
  Future<List<BookEntity>> getTrendingBooks();
  Future<List<BookEntity>> getRecommendedBooks();
  Future<List<BookEntity>> searchBooks(String query);
  Future<BookEntity?> fetchBook(String id);
  /// Ubah id buku (Google volume id / external_id) menjadi uuid di tabel books.
  Future<String?> getBookUuid(String externalId);
  Future<UserBookInteractionEntity?> getUserInteraction(String bookId);
  Future<void> updateInteraction(
    String bookId, {
    int? rating,
    String? review,
    BookReadingStatus? status,
    bool? isBookmarked,
  });
}
