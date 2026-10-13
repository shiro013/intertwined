import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_review_entity.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import 'likes_helper.dart';
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

  // Genre di aplikasi -> nama kategori Google Books (dipakai di `subject:`).
  // Genre yang tidak ada di sini dipakai apa adanya.
  static const Map<String, String> _genreSubjects = {
    'Comics & Manga': 'Comics & Graphic Novels',
    'Young Adult': 'Young Adult Fiction',
    'Technology': 'Technology & Engineering',
    'Business': 'Business & Economics',
  };

  // Batasi jumlah request ke Google Books per pemuatan Home (kuota gratis terbatas).
  static const int _maxRecommendationSources = 4;
  static const int _perSourceResults = 10;
  static const int _recommendationLimit = 20;

  List<String> _stringList(dynamic value) => (value as List? ?? [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Rekomendasi (FR-09):
  ///  - ada genre/penulis favorit -> campuran buku dari SEMUA sumber (bergantian
  ///    genre, penulis, genre, ...; maksimal 4 sumber), tanpa duplikat;
  ///  - belum ada preferensi      -> buku dengan rating tertinggi di komunitas
  ///    Intertwined, dilengkapi buku terlaris dari Google Books.
  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('favorite_genres, favorite_authors')
          .eq('id', user.id)
          .maybeSingle();

      final queries = _recommendationQueries(
        _stringList(profile?['favorite_genres']),
        _stringList(profile?['favorite_authors']),
      );
      if (queries.isEmpty) return await _defaultRecommendations();

      // Satu sumber gagal tidak boleh menggagalkan yang lain.
      final results = await Future.wait(
        queries.map(
          (q) => _fetchVolumes(q, maxResults: _perSourceResults).catchError((Object e) {
            debugPrint('Recommendation source "$q" failed: $e');
            return <BookModel>[];
          }),
        ),
      );

      final merged = _interleave(results, limit: _recommendationLimit);
      if (merged.isEmpty) return await _defaultRecommendations();

      unawaited(_syncBooksToSupabase(merged));
      return merged;
    } catch (e) {
      debugPrint('Recommended books error: $e');
      return [];
    }
  }

  /// Genre dan penulis bergantian: genre1, penulis1, genre2, penulis2, ...
  List<String> _recommendationQueries(List<String> genres, List<String> authors) {
    final genreQueries = genres.map(_genreQuery).toList();
    final authorQueries = authors.map((a) => 'inauthor:"$a"').toList();

    final queries = <String>[];
    for (var i = 0;
        queries.length < _maxRecommendationSources &&
            (i < genreQueries.length || i < authorQueries.length);
        i++) {
      if (i < genreQueries.length && queries.length < _maxRecommendationSources) {
        queries.add(genreQueries[i]);
      }
      if (i < authorQueries.length && queries.length < _maxRecommendationSources) {
        queries.add(authorQueries[i]);
      }
    }
    return queries;
  }

  String _genreQuery(String genre) {
    // "Non-Fiction" bukan kategori Google Books, jadi dicari sebagai kata kunci.
    if (genre == 'Non-Fiction') return 'nonfiction bestseller';
    return 'subject:"${_genreSubjects[genre] ?? genre}"';
  }

  /// Ambil satu per satu secara bergiliran dari tiap daftar, lewati duplikat.
  List<BookEntity> _interleave(List<List<BookEntity>> lists, {int limit = 20}) {
    final seen = <String>{};
    final out = <BookEntity>[];
    final longest = lists.fold<int>(0, (m, l) => l.length > m ? l.length : m);

    for (var i = 0; i < longest && out.length < limit; i++) {
      for (final list in lists) {
        if (i >= list.length || out.length >= limit) continue;
        if (seen.add(list[i].id)) out.add(list[i]);
      }
    }
    return out;
  }

  /// Dipakai saat pengguna belum punya preferensi: rating tertinggi di komunitas
  /// + buku terlaris (Google Books).
  Future<List<BookEntity>> _defaultRecommendations() async {
    final topRated = await _topRatedFromCommunity(limit: 10);

    List<BookEntity> popular = [];
    try {
      popular = await searchBooks('best sellers');
    } catch (e) {
      debugPrint('Default recommendations (best sellers) failed: $e');
    }
    return _interleave([topRated, popular], limit: _recommendationLimit);
  }

  /// Buku dengan rata-rata rating tertinggi dari review terbaru semua pengguna.
  Future<List<BookEntity>> _topRatedFromCommunity({int limit = 10}) async {
    try {
      final rows = await _supabase
          .from('reviews')
          .select('rating, books(*)')
          .order('created_at', ascending: false)
          .limit(300);

      final sums = <String, double>{};
      final counts = <String, int>{};
      final bookRows = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final book = row['books'];
        if (book is! Map<String, dynamic>) continue;
        final id = book['external_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        sums[id] = (sums[id] ?? 0) + ((row['rating'] as num?)?.toDouble() ?? 0);
        counts[id] = (counts[id] ?? 0) + 1;
        bookRows[id] = book;
      }

      final ids = sums.keys.toList()
        ..sort((a, b) {
          final byAverage = (sums[b]! / counts[b]!).compareTo(sums[a]! / counts[a]!);
          return byAverage != 0 ? byAverage : counts[b]!.compareTo(counts[a]!);
        });

      return ids
          .take(limit)
          .map((id) => BookModel.fromSupabase(bookRows[id]!, rating: sums[id]! / counts[id]!))
          .toList();
    } catch (e) {
      debugPrint('Top rated from community failed: $e');
      return [];
    }
  }

  /// Pencarian (FR-04): judul, penulis, atau ISBN.
  /// ISBN (10 atau 13 digit, boleh memakai spasi/strip) dicari tepat dengan `isbn:`.
  @override
  Future<List<BookEntity>> searchBooks(String query) async {
    debugPrint('--- [BOOK REPO] Starting search for: $query ---');
    try {
      final books = await _fetchVolumes(_buildSearchQuery(query), maxResults: 20);
      debugPrint('--- [BOOK REPO] ${books.length} books after filtering ---');

      // Tidak di-await: hasil pencarian tampil dulu, simpan ke DB di belakang layar
      // (detail buku tetap memakai `await` di fetchBook karena butuh baris ini).
      unawaited(_syncBooksToSupabase(books));
      return books;
    } catch (e, stacktrace) {
      debugPrint('--- [BOOK REPO] CRITICAL ERROR: $e ---');
      debugPrint('--- [BOOK REPO] STACKTRACE: $stacktrace ---');
      // Lempar ulang supaya ViewModel/UI tahu pencarian GAGAL, bukan "0 hasil"
      rethrow;
    }
  }

  static final RegExp _isbnPattern = RegExp(r'^(\d{9}[\dXx]|\d{13})$');

  String _buildSearchQuery(String raw) {
    final query = raw.trim();
    final compact = query.replaceAll(RegExp(r'[\s-]'), '');
    if (_isbnPattern.hasMatch(compact)) return 'isbn:${compact.toUpperCase()}';
    return query;
  }

  /// Satu request ke Google Books. `printType=books` membuang majalah/koran.
  Future<List<BookModel>> _fetchVolumes(String query, {required int maxResults}) async {
    final response = await http.get(
      Uri.parse(
        '$_googleBooksUrl?q=${Uri.encodeComponent(query)}'
        '&printType=books&orderBy=relevance&maxResults=$maxResults'
        '${SupabaseConfig.googleBooksKeyParam}',
      ),
    );

    if (response.statusCode != 200) {
      debugPrint('--- [BOOK REPO] API Error Body: ${response.body} ---');
      throw Exception(
        'Google Books error ${response.statusCode} '
        '(403 = API key restriction / API belum diaktifkan, 429 = kuota habis)',
      );
    }

    final data = jsonDecode(response.body);
    final items = (data['items'] as List?) ?? [];

    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => !_looksAcademic(item))
        .map(_parseGoogleVolume)
        .toList();
  }

  /// Membuang jurnal/prosiding akademik. Sengaja memeriksa JUDUL, PENERBIT dan
  /// KATEGORI saja (bukan deskripsi), supaya buku biasa yang menyebut kata
  /// "journal" (mis. "The Bullet Journal Method") tidak ikut terbuang.
  bool _looksAcademic(Map<String, dynamic> item) {
    final info = (item['volumeInfo'] ?? {}) as Map<String, dynamic>;
    final title = (info['title'] ?? '').toString().toLowerCase();
    final publisher = (info['publisher'] ?? '').toString().toLowerCase();
    final categories = (info['categories'] as List? ?? []).join(' ').toLowerCase();

    return title.startsWith('journal of') ||
        title.startsWith('proceedings') ||
        title.contains('proceedings of') ||
        title.contains('lecture notes in') ||
        publisher.contains('academic press') ||
        categories.contains('periodicals') ||
        categories.contains('conference');
  }

  Future<void> _syncBooksToSupabase(List<BookEntity> books) async {
    if (books.isEmpty) return;
    try {
      // Satu request untuk semua buku (sebelumnya 20 request berurutan)
      await _supabase.from('books').upsert(
        books
            .map((book) => {
                  'external_id': book.id, // Google volume id (bukan ISBN)
                  'title': book.title,
                  'author': book.author,
                  'cover_url': book.coverUrl,
                  'genre': book.category,
                  'synopsis': book.description,
                })
            .toList(),
        onConflict: 'external_id',
      );
    } catch (e) {
      debugPrint('Sync books error: $e');
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
    final cover = BookModel.normalizeCoverUrl(
      (images?['thumbnail'] ?? images?['smallThumbnail'] ?? '').toString(),
    );

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
        Uri.parse('$_googleBooksUrl/${Uri.encodeComponent(id)}${SupabaseConfig.googleBooksKeyParam.replaceFirst('&', '?')}'),
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

      // `limit(1)` supaya tidak error kalau (karena data lama) ada baris ganda.
      final rows = await Future.wait<Map<String, dynamic>?>([
        _supabase
            .from('reading_status')
            .select()
            .eq('user_id', user.id)
            .eq('book_id', uuid)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        _supabase
            .from('reviews')
            .select()
            .eq('user_id', user.id)
            .eq('book_id', uuid)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        _supabase
            .from('bookmarks')
            .select('id')
            .eq('user_id', user.id)
            .eq('book_id', uuid)
            .limit(1)
            .maybeSingle(),
      ]);
      final statusRow = rows[0];
      final reviewRow = rows[1];
      final bookmarkRow = rows[2];

      return UserBookInteractionEntity(
        userId: user.id,
        bookId: uuid,
        rating: (reviewRow?['rating'] as num?)?.toInt() ?? 0,
        review: (reviewRow?['review_text'] as String?) ?? '',
        // null = buku belum ada di library user
        status: statusRow == null ? null : _mapStatus(statusRow['status'] as String?),
        isBookmarked: bookmarkRow != null,
        currentPage: (statusRow?['current_page'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Get interaction error: $e');
      return null;
    }
  }

  /// Simpan satu baris per (user, buku): UPDATE kalau sudah ada, INSERT kalau belum.
  /// Sengaja TIDAK memakai `upsert(onConflict: 'user_id,book_id')` karena itu butuh
  /// unique constraint di database; tanpa constraint itu Postgres menolak query-nya.
  Future<void> _saveRow(
    String table,
    String userId,
    String bookUuid,
    Map<String, dynamic> values,
  ) async {
    final existing = await _supabase
        .from(table)
        .select('id')
        .eq('user_id', userId)
        .eq('book_id', bookUuid)
        .limit(1)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from(table).insert({
        'user_id': userId,
        'book_id': bookUuid,
        ...values,
      });
    } else {
      await _supabase.from(table).update(values).eq('id', existing['id']);
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

    final now = DateTime.now().toUtc().toIso8601String();

    if (status != null) {
      await _saveRow('reading_status', user.id, uuid, {
        'status': _statusToDb(status),
        'updated_at': now,
        'last_read_at': now,
      });
    }

    if (rating != null || review != null) {
      // kolom rating NOT NULL -> gabungkan dengan review yang sudah ada
      final existing = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', uuid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final finalRating = rating ?? (existing?['rating'] as num?)?.toInt();
      if (finalRating == null || finalRating < 1) {
        throw Exception('Beri rating bintang dulu sebelum menulis review');
      }

      await _saveRow('reviews', user.id, uuid, {
        'rating': finalRating,
        'review_text': review ?? existing?['review_text'],
        'updated_at': now,
      });
    }

    if (isBookmarked != null) {
      if (isBookmarked) {
        final existing = await _supabase
            .from('bookmarks')
            .select('id')
            .eq('user_id', user.id)
            .eq('book_id', uuid)
            .limit(1)
            .maybeSingle();
        if (existing == null) {
          await _supabase.from('bookmarks').insert({
            'user_id': user.id,
            'book_id': uuid,
          });
        }
      } else {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', uuid);
      }
    }
  }

  @override
  Future<void> removeFromLibrary(String bookId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kamu harus login dulu');

    final uuid = await _resolveExternalIdToUuid(bookId);
    if (uuid == null) return;

    await _supabase
        .from('reading_status')
        .delete()
        .eq('user_id', user.id)
        .eq('book_id', uuid);
  }

  @override
  Future<List<LibraryItemEntity>> getLibrary() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _supabase
          .from('reading_status')
          .select('status, updated_at, books(*)')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false),
      _supabase
          .from('bookmarks')
          .select('created_at, books(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false),
      _supabase.from('reviews').select('book_id, rating').eq('user_id', user.id),
    ]);

    // rating milik user, kunci = uuid buku
    final ratings = <String, double>{};
    for (final r in results[2]) {
      ratings[r['book_id'].toString()] = (r['rating'] as num?)?.toDouble() ?? 0.0;
    }

    // Kunci = external_id, jadi baris ganda (buku sama) otomatis tergabung.
    final drafts = <String, _LibraryDraft>{};

    _LibraryDraft? draftFor(dynamic bookRow) {
      if (bookRow is! Map<String, dynamic>) return null;
      final key = bookRow['external_id']?.toString() ?? '';
      if (key.isEmpty) return null;
      return drafts.putIfAbsent(key, () {
        final myRating = ratings[bookRow['id'].toString()] ?? 0.0;
        return _LibraryDraft(BookModel.fromSupabase(bookRow, rating: myRating));
      });
    }

    for (final row in results[0]) {
      final draft = draftFor(row['books']);
      if (draft == null) continue;
      // baris pertama = paling baru (sudah di-order desc)
      draft.status ??= _mapStatus(row['status'] as String?);
      draft.touch(DateTime.tryParse(row['updated_at']?.toString() ?? ''));
    }

    for (final row in results[1]) {
      final draft = draftFor(row['books']);
      if (draft == null) continue;
      draft.bookmarked = true;
      draft.touch(DateTime.tryParse(row['created_at']?.toString() ?? ''));
    }

    final list = drafts.values.toList()
      ..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    return list
        .map((d) => LibraryItemEntity(
              book: d.book,
              status: d.status,
              isBookmarked: d.bookmarked,
            ))
        .toList();
  }

  @override
  Future<List<BookReviewEntity>> getBookReviews(String bookUuid) async {
    final rows = await _supabase
        .from('reviews')
        .select('*, profiles(username, avatar_url)')
        .eq('book_id', bookUuid)
        .order('created_at', ascending: false);

    final likes = await fetchLikeInfo(
      _supabase,
      'review',
      rows.map((r) => r['id'].toString()).toList(),
    );

    return rows.map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      final id = r['id'].toString();
      final like = likes[id];
      return BookReviewEntity(
        id: id,
        userId: r['user_id'].toString(),
        username: profile?['username']?.toString(),
        avatarUrl: profile?['avatar_url']?.toString(),
        rating: (r['rating'] as num?)?.toInt() ?? 0,
        text: (r['review_text'] as String?)?.trim() ?? '',
        createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
        likeCount: like?.count ?? 0,
        likedByMe: like?.likedByMe ?? false,
      );
    }).toList();
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

class _LibraryDraft {
  _LibraryDraft(this.book);

  final BookEntity book;
  BookReadingStatus? status;
  bool bookmarked = false;
  DateTime sortKey = DateTime.fromMillisecondsSinceEpoch(0);

  void touch(DateTime? t) {
    if (t != null && t.isAfter(sortKey)) sortKey = t;
  }
}
