import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/quote.dart';

class QuoteViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<Quote> _quotes = [];
  bool _isLoading = false;

  List<Quote> get quotes => _quotes;
  bool get isLoading => _isLoading;

  Future<void> loadQuotes(String bookId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _quotes = await _bookService.getQuotesByBook(bookId);
    } catch (e) {
      debugPrint('Error loading quotes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addQuote(String bookId, String text, int? page, List<String>? tags) async {
    try {
      await _bookService.addQuote(
        bookId: bookId,
        text: text,
        page: page,
        tags: tags,
      );
      await loadQuotes(bookId); // Refresh list
      return true;
    } catch (e) {
      debugPrint('Error adding quote: $e');
      return false;
    }
  }
}
