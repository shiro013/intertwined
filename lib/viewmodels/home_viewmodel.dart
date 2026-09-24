import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<Book> _searchResults = [];
  List<Book> _recommendedBooks = [];
  bool _isSearching = false;
  bool _isLoadingRecommended = false;
  String _userName = 'Reader';

  List<Book> get searchResults => _searchResults;
  List<Book> get recommendedBooks => _recommendedBooks;
  bool get isSearching => _isSearching;
  bool get isLoadingRecommended => _isLoadingRecommended;
  String get userName => _userName;

  // Set user name from profile
  Future<void> loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();

        _userName = data['full_name'] ?? 'Reader';
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  Future<void> loadRecommendations() async {
    _isLoadingRecommended = true;
    notifyListeners();
    try {
      // Fetch trending/recommended books from Google Books via BookService (indirectly)
      // For now we access google service via BookService or we can add a method there.
      // Since BookService already has GoogleBooksService, let's add a method to BookService.
      _recommendedBooks = await _bookService.getRecommendedBooks();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      _isLoadingRecommended = false;
      notifyListeners();
    }
  }

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _bookService.searchBooks(query);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<String> addBookToLibrary(Book book) async {
    try {
      final bookId = await _bookService.persistExternalBook(book);
      // Re-search to refresh the results
      await searchBooks(_searchResults.firstWhere((b) => b.id == book.id).title);
      return bookId;
    } catch (e) {
      debugPrint('Error adding book to library: $e');
      rethrow;
    }
  }
}
