import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_review_entity.dart';
import '../../domain/entities/community_entities.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/quote_repository.dart';

class BookDetailViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final CommunityRepository _communityRepository;
  final QuoteRepository _quoteRepository;
  final FeedRepository _feedRepository;
  final VoidCallback? _onLibraryChanged;

  BookDetailViewModel({
    required BookRepository bookRepository,
    required CommunityRepository communityRepository,
    required QuoteRepository quoteRepository,
    required FeedRepository feedRepository,
    VoidCallback? onLibraryChanged,
  })  : _bookRepository = bookRepository,
        _communityRepository = communityRepository,
        _quoteRepository = quoteRepository,
        _feedRepository = feedRepository,
        _onLibraryChanged = onLibraryChanged;

  BookEntity? _book;
  String? _bookUuid; // uuid di tabel books (dipakai untuk quotes, reviews, grup)
  UserBookInteractionEntity? _interaction;
  List<BookReviewEntity> _reviews = [];
  List<QuoteEntity> _quotes = [];
  CommunityGroup? _group;
  List<CommunityDiscussion> _previewDiscussions = [];

  bool _isLoading = true;
  bool _isSocialLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Dipakai untuk mengabaikan hasil load buku lama jika user cepat pindah buku
  // (ViewModel ini dipakai bersama oleh semua halaman detail).
  int _loadToken = 0;

  BookEntity? get book => _book;
  String? get bookUuid => _bookUuid;
  UserBookInteractionEntity? get interaction => _interaction;
  String? get currentUserId => _interaction?.userId;
  List<BookReviewEntity> get reviews => _reviews;
  List<QuoteEntity> get quotes => _quotes;
  CommunityGroup? get group => _group;
  List<CommunityDiscussion> get previewDiscussions => _previewDiscussions;
  bool get isLoading => _isLoading;
  bool get isSocialLoading => _isSocialLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Rating rata-rata dari review user Intertwined (bukan dari Google Books).
  int get communityReviewCount => _reviews.length;
  double get communityAverage {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (total, r) => total + r.rating);
    return sum / _reviews.length;
  }

  void clearError() => _errorMessage = null;

  // ---------------------------------------------------------------- loading

  Future<void> loadBookDetails(String bookId) async {
    final token = ++_loadToken;
    _book = null;
    _bookUuid = null;
    _interaction = null;
    _reviews = [];
    _quotes = [];
    _group = null;
    _previewDiscussions = [];
    _errorMessage = null;
    _isLoading = true;
    _isSocialLoading = false;
    notifyListeners();

    try {
      final book = await _bookRepository.fetchBook(bookId);
      if (token != _loadToken) return;
      _book = book;

      if (book != null) {
        _bookUuid = await _bookRepository.getBookUuid(bookId);
        if (token != _loadToken) return;
        _interaction = await _bookRepository.getUserInteraction(bookId);
        if (token != _loadToken) return;
      }
    } catch (e) {
      debugPrint('Error loading book details: $e');
      _errorMessage = 'Gagal memuat buku: $e';
    }

    _isLoading = false;
    notifyListeners();

    // Bagian sosial dimuat setelah halaman utama tampil; kalau salah satu gagal
    // (mis. RLS), bagian lain tetap muncul.
    if (_bookUuid != null && token == _loadToken) {
      _isSocialLoading = true;
      notifyListeners();
      await Future.wait<void>([
        _loadReviews(token),
        _loadQuotes(token),
        _loadCommunity(token),
      ]);
      if (token == _loadToken) {
        _isSocialLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadReviews(int token) async {
    final uuid = _bookUuid;
    if (uuid == null) return;
    try {
      final reviews = await _bookRepository.getBookReviews(uuid);
      if (token != _loadToken) return;
      _reviews = reviews;
      notifyListeners();
    } catch (e) {
      debugPrint('Load reviews error: $e');
    }
  }

  Future<void> _loadQuotes(int token) async {
    final uuid = _bookUuid;
    if (uuid == null) return;
    try {
      final quotes = await _quoteRepository.fetchBookQuotes(uuid);
      if (token != _loadToken) return;
      _quotes = quotes;
      notifyListeners();
    } catch (e) {
      debugPrint('Load quotes error: $e');
    }
  }

  Future<void> _loadCommunity(int token) async {
    final uuid = _bookUuid;
    if (uuid == null) return;
    try {
      final group = await _communityRepository.findGroupForBook(uuid);
      List<CommunityDiscussion> discussions = [];
      if (group != null) {
        discussions = await _communityRepository.fetchDiscussions(group.id);
      }
      if (token != _loadToken) return;
      _group = group;
      _previewDiscussions = discussions.take(2).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load community preview error: $e');
    }
  }

  /// Dipanggil setelah user kembali dari halaman diskusi buku.
  Future<void> refreshCommunity() => _loadCommunity(_loadToken);

  // -------------------------------------------------------------- mutations

  /// Jalankan aksi tulis. Mengembalikan true hanya kalau benar-benar berhasil
  /// (UI memakai ini untuk snackbar sukses; jangan andalkan errorMessage karena
  /// sudah dibersihkan oleh UI).
  Future<bool> _run(Future<void> Function() action, {bool refreshReviews = false}) async {
    final book = _book;
    if (book == null) return false;

    var ok = false;
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      ok = true;
    } catch (e) {
      debugPrint('Interaction error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    // Selalu sinkron ulang dengan database (juga saat gagal -> mengembalikan
    // tampilan optimistic yang salah).
    try {
      _interaction = await _bookRepository.getUserInteraction(book.id);
    } catch (e) {
      debugPrint('Reload interaction error: $e');
    }
    if (ok && refreshReviews) await _loadReviews(_loadToken);

    _isSaving = false;
    notifyListeners();
    if (ok) _onLibraryChanged?.call();
    return ok;
  }

  /// `null` = keluarkan dari library.
  Future<bool> setReadingStatus(BookReadingStatus? status) {
    return _run(() {
      final id = _book!.id;
      return status == null
          ? _bookRepository.removeFromLibrary(id)
          : _bookRepository.updateInteraction(id, status: status);
    });
  }

  Future<bool> updateRating(int rating) {
    return _run(
      () => _bookRepository.updateInteraction(_book!.id, rating: rating),
      refreshReviews: true,
    );
  }

  Future<bool> saveReview(String text) async {
    final trimmed = text.trim();
    final changed = trimmed != (_interaction?.review ?? '').trim();
    final ok = await _run(
      () => _bookRepository.updateInteraction(_book!.id, review: trimmed),
      refreshReviews: true,
    );
    if (ok && changed && trimmed.isNotEmpty) {
      _postFeed('post_review', trimmed);
    }
    return ok;
  }

  Future<bool> toggleBookmark() async {
    final current = _interaction?.isBookmarked ?? false;
    // optimistic: ikon langsung berubah, lalu disinkronkan dengan database
    if (_interaction != null) {
      _interaction = _interaction!.copyWith(isBookmarked: !current);
      notifyListeners();
    }
    return _run(
      () => _bookRepository.updateInteraction(_book!.id, isBookmarked: !current),
    );
  }

  Future<void> toggleReviewLike(String reviewId) async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return;
    }
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index < 0) return;

    final before = _reviews[index];
    final nowLiked = !before.likedByMe;
    _reviews[index] = before.copyWith(
      likedByMe: nowLiked,
      likeCount: math.max(0, before.likeCount + (nowLiked ? 1 : -1)),
    );
    notifyListeners();

    try {
      await _communityRepository.setLike(userId, reviewId, 'review', nowLiked);
    } catch (e) {
      debugPrint('Review like error: $e');
      final i = _reviews.indexWhere((r) => r.id == reviewId);
      if (i >= 0) _reviews[i] = before;
      _errorMessage = 'Gagal menyimpan like';
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------- quotes

  Future<bool> addQuote(String text, int pageNumber, List<String> tags) async {
    final uuid = _bookUuid;
    final userId = currentUserId;
    if (uuid == null || userId == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return false;
    }
    try {
      await _quoteRepository.saveQuote(userId, uuid, text, pageNumber, tags);
    } catch (e) {
      debugPrint('Save quote error: $e');
      _errorMessage = 'Gagal menyimpan quote: $e';
      notifyListeners();
      return false;
    }
    await _loadQuotes(_loadToken);
    _postFeed('share_quote', text);
    _onLibraryChanged?.call(); // statistik "Quotes Saved" di profil
    return true;
  }

  Future<void> removeQuote(String quoteId) async {
    try {
      await _quoteRepository.deleteQuote(quoteId);
      _quotes.removeWhere((q) => q.id == quoteId);
      notifyListeners();
      _onLibraryChanged?.call();
    } catch (e) {
      debugPrint('Delete quote error: $e');
      _errorMessage = 'Gagal menghapus quote';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------- feed

  /// Aktivitas untuk feed "Community Activity" di Home. Gagal = tidak masalah.
  Future<void> _postFeed(String type, String preview) async {
    final userId = currentUserId;
    final uuid = _bookUuid;
    if (userId == null || uuid == null) return;
    try {
      final short = preview.length > 140 ? '${preview.substring(0, 140)}…' : preview;
      await _feedRepository.postActivity(userId, type, bookId: uuid, preview: short);
    } catch (e) {
      debugPrint('Post feed activity error: $e');
    }
  }
}
