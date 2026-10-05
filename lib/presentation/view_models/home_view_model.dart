import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../domain/entities/book_entity.dart';
import '../../domain/entities/feed_activity_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/feed_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final FeedRepository _feedRepository;

  HomeViewModel(this._bookRepository, this._feedRepository);

  List<BookEntity> _books = [];
  List<BookEntity> _recommendedBooks = []; // disimpan untuk dipulihkan saat pencarian dihapus
  List<BookEntity> _trendingBooks = [];
  List<FeedActivityEntity> _feedActivities = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _searchDebounce;

  // Pencarian punya status sendiri. JANGAN pakai _isLoading: HomeScreen mengganti
  // seluruh halaman (termasuk kolom search) dengan skeleton saat _isLoading = true,
  // sehingga kolom search hancur dan terlihat seperti "keluar dari search".
  String _searchQuery = '';
  bool _isSearching = false;
  int _searchToken = 0; // mengabaikan respons lama kalau user sudah mengetik hal lain

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get isSearchActive => _searchQuery.trim().isNotEmpty;

  List<BookEntity> get books => _books;
  List<BookEntity> get trendingBooks => _trendingBooks;
  List<FeedActivityEntity> get feedActivities => _feedActivities;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Fix: Execute separately instead of Future.wait to isolate failures
      try {
        _recommendedBooks = await _bookRepository.getRecommendedBooks();
        // jangan timpa hasil pencarian yang sedang tampil
        if (!isSearchActive) _books = _recommendedBooks;
      } catch (e) {
        debugPrint('Recommended books failed: $e');
      }

      try {
        _trendingBooks = await _bookRepository.getTrendingBooks();
      } catch (e) {
        debugPrint('Trending books failed: $e');
      }

      try {
        _feedActivities = await _feedRepository.fetchFeed();
      } catch (e) {
        debugPrint('Feed failed: $e');
      }
    } catch (e) {
      _errorMessage = 'Failed to load home data: $e';
      debugPrint('General home load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dipanggil setiap huruf diketik (di-debounce 500 ms).
  Future<void> searchBooks(String query) async {
    _searchDebounce?.cancel();
    _searchQuery = query;

    if (query.trim().isEmpty) {
      // pencarian dihapus -> kembali ke rekomendasi tanpa request jaringan
      _searchToken++;
      _isSearching = false;
      _errorMessage = null;
      _books = _recommendedBooks;
      notifyListeners();
      return;
    }

    notifyListeners(); // sembunyikan Trending/Feed segera
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _runSearch(query.trim()),
    );
  }

  /// Tombol Enter / ikon search di keyboard: cari sekarang tanpa menunggu debounce.
  Future<void> submitSearch(String query) async {
    _searchDebounce?.cancel();
    _searchQuery = query;
    if (query.trim().isEmpty) return searchBooks('');
    await _runSearch(query.trim());
  }

  void clearSearch() => searchBooks('');

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    _isSearching = true;
    _errorMessage = null;
    _selectedCategory = 'All'; // filter kategori lama bisa menyembunyikan semua hasil
    notifyListeners();

    try {
      final results = await _bookRepository.searchBooks(query);
      if (token != _searchToken) return;
      _books = results;
    } catch (e) {
      if (token != _searchToken) return;
      _books = [];
      _errorMessage = 'Search failed: ${e.toString().replaceFirst('Exception: ', '')}';
      debugPrint('Error searching books: $e');
    } finally {
      if (token == _searchToken) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<BookEntity> get filteredBooks {
    if (_selectedCategory == 'All') return _books;
    return _books.where((b) => b.category == _selectedCategory).toList();
  }

  Future<void> loadBooks() async {
    await loadHomeData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}