import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../services/google_books_service.dart';
import '../models/book.dart';
import '../models/reading_status.dart';

class BookDetailViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  Book? _book;
  String? _currentStatus;
  bool _isLoading = false;

  Book? get book => _book;
  String? get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;

  Future<void> loadBookDetails(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Coba cari di database internal dulu
      // Jika bookId adalah UUID, ini akan berhasil. Jika ID Google, ini akan return null.
      final localBook = await _bookService.getBookDetails(bookId);

      if (localBook != null) {
        _book = localBook;
      } else {
        // 2. Jika tidak ada di Supabase, ambil dari Google Books API
        // Ini adalah penyelamat agar tidak muncul "Book Not Found"
        final externalBook = await _googleBooksService.getBookDetails(bookId);
        if (externalBook != null) {
          _book = externalBook;
        }
      }

      if (_book == null) {
        throw Exception('Book not found in both Supabase and Google Books');
      }

      // 3. Ambil status baca user (hanya jika buku ini sudah ada di Supabase)
      // Jika buku masih eksternal, status akan null sampai user klik (+) di Home
      try {
        final status = await _bookService.getReadingStatus(_book!.id);
        _currentStatus = status?.status.toDbValue();
      } catch (e) {
        debugPrint('No reading status for this book: $e');
      }
    } catch (e) {
      debugPrint('CRITICAL ERROR loading book details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String status) async {
    if (_book == null) return false;

    try {
      await _bookService.updateReadingStatus(_book!.id, status);
      _currentStatus = status;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    }
  }
}
