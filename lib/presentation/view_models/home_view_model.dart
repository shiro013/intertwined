import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/feed_activity_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/feed_repository.dart';

enum ViewStatus { loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final FeedRepository _feedRepository;

  HomeViewModel(this._bookRepository, this._feedRepository);

  List<BookEntity> _books = [];
  List<BookEntity> _trendingBooks = [];
  List<FeedActivityEntity> _feedActivities = [];
  String _selectedCategory = 'All';
  ViewStatus _status = ViewStatus.loading;
  String? _errorMessage;
  final bool _simulateError = false; // Set to true to test ErrorView

  List<BookEntity> get books => _books;
  List<BookEntity> get trendingBooks => _trendingBooks;
  List<FeedActivityEntity> get feedActivities => _feedActivities;
  String get selectedCategory => _selectedCategory;
  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ViewStatus.loading;

  Future<void> loadHomeData() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      if (_simulateError) {
        throw Exception('Gagal memuat data. Periksa koneksi internet.');
      }

      _books = await _bookRepository.getRecommendedBooks();
      _trendingBooks = await _bookRepository.getTrendingBooks();

      // Feed is kept as is, but since we use mocks, it might be empty
      try {
        _feedActivities = await _feedRepository.fetchFeed();
      } catch (e) {
        debugPrint('Feed failed: $e');
      }

      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ViewStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      await loadHomeData();
      return;
    }

    _status = ViewStatus.loading;
    notifyListeners();
    try {
      _books = await _bookRepository.searchBooks(query);
      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _status = ViewStatus.error;
    } finally {
      notifyListeners();
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
}
