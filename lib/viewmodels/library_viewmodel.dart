import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/book.dart';
import '../models/reading_status.dart';
import '../models/library_item.dart';

class LibraryViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<LibraryItem> _myBooks = [];
  bool _isLoading = false;

  List<LibraryItem> get myBooks => _myBooks;
  bool get isLoading => _isLoading;

  // Filter buku berdasarkan status
  List<LibraryItem> get wantToReadBooks =>
      _myBooks.where((item) => item.status.status == ReadingStatusType.wantToRead).toList();

  List<LibraryItem> get currentlyReadingBooks =>
      _myBooks.where((item) => item.status.status == ReadingStatusType.reading).toList();

  List<LibraryItem> get finishedBooks =>
      _myBooks.where((item) => item.status.status == ReadingStatusType.finished).toList();

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _bookService.getUserLibrary();
      _myBooks = data.map((json) => LibraryItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
