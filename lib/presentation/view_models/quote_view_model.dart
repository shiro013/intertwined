import 'package:flutter/material.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quote_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteViewModel extends ChangeNotifier {
  final QuoteRepository _quoteRepository;

  QuoteViewModel(this._quoteRepository);

  List<QuoteEntity> _userQuotes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<QuoteEntity> get userQuotes => _userQuotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserQuotes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _userQuotes = await _quoteRepository.fetchUserQuotes(user.id);
    } catch (e) {
      _errorMessage = 'Failed to load quotes: $e';
      debugPrint('Error loading quotes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuote(String bookId, String text, int pageNumber, List<String> tags) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _quoteRepository.saveQuote(user.id, bookId, text, pageNumber, tags);
      await loadUserQuotes(); // Refresh list
    } catch (e) {
      _errorMessage = 'Failed to save quote: $e';
      debugPrint('Error saving quote: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeQuote(String quoteId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _quoteRepository.deleteQuote(quoteId);
      _userQuotes.removeWhere((q) => q.id == quoteId);
    } catch (e) {
      _errorMessage = 'Failed to delete quote: $e';
      debugPrint('Error deleting quote: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
