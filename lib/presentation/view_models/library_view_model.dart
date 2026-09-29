import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/book_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final BookRepository _repository;

  List<BookEntity> _myBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Stats
  int _totalBooksRead = 0;
  int _totalQuotesSaved = 0;
  int _totalGroupsJoined = 0;

  LibraryViewModel(this._repository);

  List<BookEntity> get myBooks => _myBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalBooksRead => _totalBooksRead;
  int get totalQuotesSaved => _totalQuotesSaved;
  int get totalGroupsJoined => _totalGroupsJoined;

  List<BookEntity> get readingBooks => [];
  List<BookEntity> get finishedBooks => [];
  List<BookEntity> get wantToReadBooks => [];

  Future<void> loadLibrary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Mocking library data
      await Future.delayed(const Duration(seconds: 1));
      _myBooks = await _repository.getRecommendedBooks();
      _totalBooksRead = 5;
      _totalQuotesSaved = 12;
      _totalGroupsJoined = 2;
    } catch (e) {
      _errorMessage = 'Failed to load library: $e';
      debugPrint('Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
