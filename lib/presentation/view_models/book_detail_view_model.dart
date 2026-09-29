import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../../domain/repositories/book_repository.dart';

class BookDetailViewModel extends ChangeNotifier {
  final BookRepository _repository;
  BookEntity? _book;
  String? _bookUuid; // uuid di tabel books (dipakai untuk quotes, dll)
  UserBookInteractionEntity? _interaction;
  bool _isLoading = true;
  String? _errorMessage;

  BookDetailViewModel({required BookRepository bookRepository})
      : _repository = bookRepository;

  BookEntity? get book => _book;
  String? get bookUuid => _bookUuid;
  UserBookInteractionEntity? get interaction => _interaction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() => _errorMessage = null;

  Future<void> loadBookDetails(String bookId) async {
    // Reset: ViewModel ini dipakai bersama, jangan tampilkan buku sebelumnya
    _book = null;
    _bookUuid = null;
    _interaction = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      _book = await _repository.fetchBook(bookId);
      if (_book != null) {
        _bookUuid = await _repository.getBookUuid(bookId);
        _interaction = await _repository.getUserInteraction(bookId);
      }
    } catch (e) {
      debugPrint('Error loading book details: $e');
      _errorMessage = 'Gagal memuat buku: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<void> Function() action, String label) async {
    if (_book == null) return;
    try {
      await action();
      _interaction = await _repository.getUserInteraction(_book!.id);
    } catch (e) {
      debugPrint('Error $label: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> updateReadingStatus(BookReadingStatus status) =>
      _run(() => _repository.updateInteraction(_book!.id, status: status), 'updating status');

  Future<void> updateRating(int rating) =>
      _run(() => _repository.updateInteraction(_book!.id, rating: rating), 'updating rating');

  Future<void> updateReview(String review) =>
      _run(() => _repository.updateInteraction(_book!.id, review: review), 'updating review');

  Future<void> toggleBookmark() {
    final current = _interaction?.isBookmarked ?? false;
    return _run(
      () => _repository.updateInteraction(_book!.id, isBookmarked: !current),
      'toggling bookmark',
    );
  }
}
