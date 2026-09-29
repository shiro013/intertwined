import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../models/book_model.dart';
import '../../core/constants/supabase_config.dart';

class BookRepositoryImpl implements BookRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _googleBooksUrl = 'https://www.googleapis.com/books/v1/volumes';

  @override
  Future<List<BookEntity>> getTrendingBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((row) => BookModel.fromSupabase(row as Map<String, dynamic>))
          .where((b) => b.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Trending books error: $e');
      return [];
    }
  }

  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('favorite_genres')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return await searchBooks('best sellers');

      final data = profile;
      final List<String> genres = (data['favorite_genres'] as List? ?? []).cast<String>();
      if (genres.isEmpty) {
        return await searchBooks('best sellers');
      }

      return await searchBooks(genres.first);
    } catch (e) {
      debugPrint('Recommended books error: $e');
      return [];
    }
  }

  @override
  Future<List<BookEntity>> searchBooks(String query) async {
    debugPrint('--- [BOOK REPO] Starting search for: $query ---');
    try {
      final response = await http.get(
        Uri.parse('$_googleBooksUrl?q=${Uri.encodeComponent(query)}&orderBy=relevance&maxResults=20&key=${SupabaseConfig.googleBooksApiKey}'),
      );

      debugPrint('--- [BOOK REPO] API Response Code: ${response.statusCode} ---');

      if (response.statusCode != 200) {
        debugPrint('--- [BOOK REPO] API Error Body: ${response.body} ---');
        throw Exception('Failed to fetch books from Google: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final List items = data['items'] ?? [];
      debugPrint('--- [BOOK REPO] API found ${items.length} items ---');

      final books = items.map((item) {
        return _parseGoogleVolume(item as Map<String, dynamic>);
      }).where((book) {
        final text = (book.title + book.description).toLowerCase();
        final isAcademic = text.contains('journal') ||
                           text.contains('proceedings') ||
                           text.contains('academic press') ||
                           text.contains('lecture notes');
        return !isAcademic;
      }).toList();

      debugPrint('--- [BOOK REPO] After filtering: ${books.length} books remaining ---');

      await _syncBooksToSupabase(books);

      return books;
    } catch (e, stacktrace) {
      debugPrint('--- [BOOK REPO] CRITICAL ERROR: $e ---');
      debugPrint('--- [BOOK REPO] STACKTRACE: $stacktrace ---');
      return [];
    }
  }

  Future<void> _syncBooksToSupabase(List<BookEntity> books) async {
    for (var book in books) {
      try {
        await _supabase.from('books').upsert({
          'external_id': book.id, // Google volume id (bukan ISBN)
          'title': book.title,
          'author': book.author,
          'cover_url': book.coverUrl,
          'genre': book.category,
          'synopsis': book.description,
        }, onConflict: 'external_id');
      } catch (e) {
        debugPrint('Sync book error (${book.id}): $e');
      }
    }
  }


  /// Ubah satu item Google Books (volume) menjadi BookModel.
  BookModel _parseGoogleVolume(Map<String, dynamic> item) {
    final volumeInfo = (item['volumeInfo'] ?? {}) as Map<String, dynamic>;
    final categories = volumeInfo['categories'] as List? ?? [];

    String isbn = '';
    final identifiers = volumeInfo['industryIdentifiers'] as List?;
    if (identifiers != null && identifiers.isNotEmpty) {
      final firstId = identifiers[0] as Map<String, dynamic>?;
      isbn = firstId?['identifier'] ?? '';
    }

    // Google memakai `imageLinks`, bukan `image`; dan sering http:// (diblok browser)
    final images = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final cover = (images?['thumbnail'] ?? images?['smallThumbnail'] ?? '')
        .toString()
        .replaceFirst('http://', 'https://');

    final avg = (volumeInfo['averageRating'] as num? ?? 0).toDouble();

    return BookModel(
      id: item['id'].toString(),
      title: volumeInfo['title'] ?? 'Unknown Title',
      author: (volumeInfo['authors'] as List? ?? ['Unknown Author']).join(', '),
      coverUrl: cover,
      category: categories.isNotEmpty ? categories.first : 'Unknown',
      rating: avg,
      description: volumeInfo['description'] ?? 'No description available.',
      isbn: isbn,
      averageRating: avg,
      totalReviews: volumeInfo['ratingsCount'] as int? ?? 0,
    );
  }

  @override
  Future<BookEntity?> fetchBook(String id) async {
    try {
      // 1. Cari di Supabase lewat external_id (= id yang dipakai seluruh UI)
      final response = await _supabase
          .from('books')
          .select()
          .eq('external_id', id)
          .maybeSingle();

      if (response != null) {
        return BookModel.fromSupabase(response);
      }

      // 2. Belum ada di DB -> ambil dari Google Books
      debugPrint('--- [BOOK REPO] Book not in DB, fetching from Google: $id ---');
      final googleResponse = await http.get(
        Uri.parse('$_googleBooksUrl/${Uri.encodeComponent(id)}?key=${SupabaseConfig.googleBooksApiKey}'),
      );

      if (googleResponse.statusCode == 200) {
        final book = _parseGoogleVolume(
          jsonDecode(googleResponse.body) as Map<String, dynamic>,
        );
        // WAJIB di-await: langkah berikutnya (rating/status) butuh baris ini sudah ada
        await _syncBooksToSupabase([book]);
        return book;
      }

      debugPrint('--- [BOOK REPO] Google fetch failed: ${googleResponse.statusCode} ---');
      return null;
    } catch (e) {
      debugPrint('Fetch book error: $e');
      return null;
    }
  }

  Future<String?> _resolveExternalIdToUuid(String externalId) async {
    try {
      final response = await _supabase
          .from('books')
          .select('id')
          .eq('external_id', externalId)
          .maybeSingle();

      if (response == null) return null;
      return response['id'] as String?;
    } catch (e) {
      debugPrint('ID resolution error: $e');
      return null;
    }
  }

  @override
  Future<String?> getBookUuid(String externalId) => _resolveExternalIdToUuid(externalId);

  @override
  Future<UserBookInteractionEntity?> getUserInteraction(String bookId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final uuid = await _resolveExternalIdToUuid(bookId);
      if (uuid == null) return null;

      final statusRow = await _supabase
          .from('reading_status')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', uuid)
          .maybeSingle();

      final reviewRow = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', uuid)
          .maybeSingle();

      final bookmarkRow = await _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_id', user.id)
          .eq('book_id', uuid)
          .maybeSingle();

      return UserBookInteractionEntity(
        userId: user.id,
        bookId: uuid,
        rating: (reviewRow?['rating'] as int?) ?? 0,
        review: (reviewRow?['review_text'] as String?) ?? '',
        status: _mapStatus(statusRow?['status'] as String?),
        isBookmarked: bookmarkRow != null,
        currentPage: (statusRow?['current_page'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('Get interaction error: $e');
      return null;
    }
  }

  @override
  Future<void> updateInteraction(
    String bookId, {
    int? rating,
    String? review,
    BookReadingStatus? status,
    bool? isBookmarked,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kamu harus login dulu');

    final uuid = await _resolveExternalIdToUuid(bookId);
    if (uuid == null) {
      throw Exception('Buku belum tersimpan di database (external_id: $bookId)');
    }

    if (status != null) {
      await _supabase.from('reading_status').upsert({
        'user_id': user.id,
        'book_id': uuid,
        'status': _statusToDb(status),
        'updated_at': DateTime.now().toIso8601String(),
        'last_read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,book_id');
    }

    if (rating != null || review != null) {
      // kolom rating NOT NULL -> gabungkan dengan review yang sudah ada
      final existing = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', uuid)
          .maybeSingle();

      final finalRating = rating ?? (existing?['rating'] as int?);
      if (finalRating == null || finalRating < 1) {
        throw Exception('Beri rating bintang dulu sebelum menulis review');
      }

      await _supabase.from('reviews').upsert({
        'user_id': user.id,
        'book_id': uuid,
        'rating': finalRating,
        'review_text': review ?? existing?['review_text'],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,book_id');
    }

    if (isBookmarked != null) {
      if (isBookmarked) {
        await _supabase.from('bookmarks').upsert({
          'user_id': user.id,
          'book_id': uuid,
        }, onConflict: 'user_id,book_id');
      } else {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', uuid);
      }
    }
  }

  // Nilai harus sama persis dengan CHECK constraint di tabel reading_status
  String _statusToDb(BookReadingStatus s) {
    switch (s) {
      case BookReadingStatus.wantToRead:
        return 'Want to Read';
      case BookReadingStatus.reading:
        return 'Reading';
      case BookReadingStatus.finished:
        return 'Finished';
    }
  }

  BookReadingStatus _mapStatus(String? status) {
    switch (status) {
      case 'Reading':
        return BookReadingStatus.reading;
      case 'Finished':
        return BookReadingStatus.finished;
      case 'Want to Read':
      default:
        return BookReadingStatus.wantToRead;
    }
  }
}
