import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/quote.dart';
import '../models/review.dart';
import '../models/book_group.dart';
import '../models/discussion.dart';
import '../models/reading_status.dart';
import 'google_books_service.dart';

class BookService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  // Cari buku berdasarkan keyword (judul, penulis, atau ISBN) - FR-03
  Future<List<Book>> searchBooks(String keyword) async {
    // 1. Cari di internal Supabase dulu
    final localResponse = await _supabase
        .from('books')
        .select()
        .or('title.ilike.%$keyword%,author.ilike.%$keyword%,id.eq.$keyword');

    final localBooks = (List<Map<String, dynamic>>.from(localResponse))
        .map((json) => Book.fromJson(json))
        .toList();

    // 2. Cari di Google Books API untuk melengkapi hasil
    final externalBooks = await _googleBooksService.searchBooks(keyword);

    // Gabungkan hasil. Kita bisa return semua, tapi di UI nanti bisa dibedakan
    // Jika ingin menghindari duplikat berdasarkan ISBN, kita bisa filter di sini
    final allBooks = [...localBooks, ...externalBooks];

    return allBooks;
  }

  // Simpan buku eksternal ke database Supabase
  Future<String> persistExternalBook(Book book) async {
    try {
      // 1. Cek apakah buku sudah ada berdasarkan ISBN agar tidak duplikat
      if (book.isbn != null) {
        final existing = await _supabase
            .from('books')
            .select('id')
            .eq('isbn', book.isbn!)
            .maybeSingle();

        if (existing != null) {
          return existing['id'] as String;
        }
      }

      // 2. Simpan ke tabel books
      // Kita tidak mengirimkan 'id' dari Google agar Supabase membuat UUID sendiri secara otomatis
      final response = await _supabase.from('books').insert({
        'title': book.title,
        'author': book.author,
        'isbn': book.isbn,
        'description': book.description,
        'cover_url': book.coverUrl,
        'genre': book.genre,
        'synopsis': book.synopsis,
      }).select().single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('CRITICAL ERROR in persistExternalBook: $e');
      rethrow;
    }
  }

  // Ambil detail buku - FR-04
  Future<Book?> getBookDetails(String bookId) async {
    try {
      // 1. Coba cari di database internal dulu
      final response = await _supabase
          .from('books')
          .select()
          .eq('id', bookId)
          .maybeSingle();

      if (response != null) {
        return Book.fromJson(response);
      }

      // 2. Jika tidak ada, ambil dari Google Books API (Hybrid Approach)
      return await _googleBooksService.getBookDetails(bookId);
    } catch (e) {
      debugPrint('Error in getBookDetails: $e');
      return null;
    }
  }

  // Ambil status baca user untuk buku tertentu - FR-12
  Future<ReadingStatus?> getReadingStatus(String bookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('reading_status')
        .select()
        .eq('book_id', bookId)
        .eq('user_id', userId)
        .maybeSingle();

    return response == null ? null : ReadingStatus.fromJson(response);
  }

  // Update atau Tambah status baca - FR-12
  Future<void> updateReadingStatus(String bookId, String status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('reading_status').upsert({
      'user_id': userId,
      'book_id': bookId,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Ambil semua kutipan untuk buku tertentu - FR-09
  Future<List<Quote>> getQuotesByBook(String bookId) async {
    final response = await _supabase
        .from('quotes')
        .select('*, profiles(username)')
        .eq('book_id', bookId)
        .order('created_at');

    return (List<Map<String, dynamic>>.from(response))
        .map((json) => Quote.fromJson(json))
        .toList();
  }

  // Tambah kutipan baru - FR-07
  Future<void> addQuote({
    required String bookId,
    required String text,
    int? page,
    List<String>? tags,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('quotes').insert({
      'user_id': userId,
      'book_id': bookId,
      'quote_text': text,
      'page_number': page,
      'tags': tags,
    });
  }

  // Ambil semua review untuk buku tertentu - FR-06
  Future<List<Review>> getReviewsByBook(String bookId) async {
    final response = await _supabase
        .from('reviews')
        .select('*, profiles(username)')
        .eq('book_id', bookId)
        .order('created_at');

    return (List<Map<String, dynamic>>.from(response))
        .map((json) => Review.fromJson(json))
        .toList();
  }

  // Tambah atau update review - FR-05, FR-06
  Future<void> addReview({
    required String bookId,
    required int rating,
    required String text,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('reviews').upsert({
      'user_id': userId,
      'book_id': bookId,
      'rating': rating,
      'review_text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Ambil rekomendasi buku untuk Home Screen
  Future<List<Book>> getRecommendedBooks() async {
    return await _googleBooksService.getTrendingBooks();
  }

  // AMBIL KOLEKSI BUKU USER (FR-12, FR-17)
  Future<List<Map<String, dynamic>>> getUserLibrary() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('reading_status')
        .select('*, books(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // FITUR FEED: Ambil aktivitas campuran (Kutipan & Review Terbaru) - FR-20
  Future<List<Map<String, dynamic>>> getGlobalFeed() async {
    final quotes = await _supabase
        .from('quotes')
        .select('*, profiles(username), books(title)')
        .order('created_at')
        .limit(20);

    final List<Map<String, dynamic>> feed = [];
    for (var q in quotes) {
      feed.add({'type': 'quote', 'data': Quote.fromJson(q), 'created_at': q['created_at']});
    }

    final reviews = await _supabase
        .from('reviews')
        .select('*, profiles(username), books(title)')
        .order('created_at')
        .limit(20);

    for (var r in reviews) {
      feed.add({'type': 'review', 'data': Review.fromJson(r), 'created_at': r['created_at']});
    }

    feed.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

    return feed;
  }

  // === FITUR BOOK CLUBS (FR-18, FR-19) ===

  Future<List<BookGroup>> getGroups() async {
    final response = await _supabase
        .from('groups')
        .select('*, books(title)')
        .order('created_at');
    return (List<Map<String, dynamic>>.from(response))
        .map((json) => BookGroup.fromJson(json))
        .toList();
  }

  Future<void> createGroup({
    required String name,
    required String description,
    String? bookId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('groups').insert({
      'name': name,
      'description': description,
      'book_id': bookId,
      'created_by': userId,
    });
  }

  Future<void> joinGroup(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }

  Future<List<Discussion>> getGroupDiscussions(String groupId) async {
    final response = await _supabase
        .from('discussions')
        .select('*, profiles(username)')
        .eq('group_id', groupId)
        .order('created_at');

    return (List<Map<String, dynamic>>.from(response))
        .map((json) => Discussion.fromJson(json))
        .toList();
  }

  Future<void> sendDiscussionMessage(String groupId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('discussions').insert({
      'group_id': groupId,
      'user_id': userId,
      'content': content,
    });
  }
}
