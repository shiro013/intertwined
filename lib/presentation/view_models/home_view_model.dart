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
  List<BookEntity> _trendingBooks = [];
  List<FeedActivityEntity> _feedActivities = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _searchDebounce;

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
        _books = await _bookRepository.getRecommendedBooks();
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

  Future<void> searchBooks(String query) async {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        await loadHomeData();
        return;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        _books = await _bookRepository.searchBooks(query);
      } catch (e) {
        _errorMessage = 'Search failed: $e';
        debugPrint('Error searching books: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
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