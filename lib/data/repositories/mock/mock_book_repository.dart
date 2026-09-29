import '../../../domain/repositories/book_repository.dart';
import '../../../domain/entities/book_entity.dart';
import '../../../domain/entities/user_book_interaction_entity.dart';

class MockBookRepository implements BookRepository {
  static final List<BookEntity> _dummyBooks = [
    BookEntity(
      id: '1',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      coverUrl: 'https://via.placeholder.com/150',
      category: 'Classic',
      rating: 4.5,
      description: 'A story of wealth, love, and the American Dream in the 1920s.',
      isbn: '1234567890',
      averageRating: 4.2,
      totalReviews: 120,
    ),
    BookEntity(
      id: '2',
      title: '1984',
      author: 'George Orwell',
      coverUrl: 'https://via.placeholder.com/150',
      category: 'Dystopian',
      rating: 4.8,
      description: 'A chilling prophecy about totalitarianism and surveillance.',
      isbn: '0987654321',
      averageRating: 4.7,
      totalReviews: 250,
    ),
    BookEntity(
      id: '3',
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      coverUrl: 'https://via.placeholder.com/150',
      category: 'Fantasy',
      rating: 4.9,
      description: 'An unexpected journey of a hobbit in Middle-earth.',
      isbn: '1122334455',
      averageRating: 4.8,
      totalReviews: 500,
    ),
  ];

  @override
  Future<List<BookEntity>> getTrendingBooks() async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyBooks;
  }

  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyBooks.reversed.toList();
  }

  @override
  Future<List<BookEntity>> searchBooks(String query) async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyBooks.where((b) => b.title.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<BookEntity?> fetchBook(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      return _dummyBooks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getBookUuid(String externalId) async {
    return 'mock-uuid-$externalId';
  }

  @override
  Future<UserBookInteractionEntity?> getUserInteraction(String bookId) async {
    return UserBookInteractionEntity(
      bookId: bookId,
      userId: 'mock-user',
      rating: 4,
      review: 'Great book!',
      status: BookReadingStatus.finished,
      isBookmarked: true,
      lastReadAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateInteraction(String bookId, {int? rating, String? review, BookReadingStatus? status, bool? isBookmarked}) async {
    // Dummy update - do nothing
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
