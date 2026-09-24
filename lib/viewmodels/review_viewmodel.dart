import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/review.dart';

class ReviewViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<Review> _reviews = [];
  bool _isLoading = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> loadReviews(String bookId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _reviews = await _bookService.getReviewsByBook(bookId);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview(String bookId, int rating, String text) async {
    try {
      await _bookService.addReview(
        bookId: bookId,
        rating: rating,
        text: text,
      );
      await loadReviews(bookId); // Refresh list
      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }
}
