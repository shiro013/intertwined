import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quote_repository.dart';

class QuoteViewModel extends ChangeNotifier {
  final QuoteRepository _quoteRepository;

  QuoteViewModel(this._quoteRepository);

  // ---- koleksi pribadi (FR-13)
  List<QuoteEntity> _userQuotes = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  // ---- pencarian semua kutipan (FR-12)
  List<QuoteEntity> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _lastQuery = '';
  String? _searchError;
  int _searchToken = 0; // abaikan respons lama kalau user sudah mengetik hal lain

  // Logout me-reset pohon widget (lihat main.dart); hindari notify setelah dispose.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  List<QuoteEntity> get userQuotes => _userQuotes;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  void clearError() => _errorMessage = null;

  List<QuoteEntity> get results => _results;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String get lastQuery => _lastQuery;
  String? get searchError => _searchError;

  /// Semua tag unik milik user, yang paling sering dipakai di depan.
  List<String> get userTags {
    final counts = <String, int>{};
    for (final quote in _userQuotes) {
      for (final tag in quote.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final tags = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return tags;
  }

  /// Saring koleksi pribadi: [query] dicocokkan dengan isi kutipan, judul buku,
  /// dan tag; [tag] (jika ada) harus ada di tag kutipan.
  List<QuoteEntity> filterUserQuotes({String query = '', String? tag}) {
    final q = query.trim().toLowerCase();
    final t = tag?.trim().toLowerCase();

    return _userQuotes.where((quote) {
      if (t != null && t.isNotEmpty && !quote.tags.any((x) => x.trim().toLowerCase() == t)) {
        return false;
      }
      if (q.isEmpty) return true;
      return quote.text.toLowerCase().contains(q) ||
          quote.bookTitle.toLowerCase().contains(q) ||
          quote.tags.any((x) => x.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> loadUserQuotes({bool silent = false}) async {
    final userId = currentUserId;
    if (userId == null) return;

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _userQuotes = await _quoteRepository.fetchUserQuotes(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load your quotes. Please try again.';
      debugPrint('Error loading quotes: $e');
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final q = query.trim();
    final token = ++_searchToken;

    if (q.isEmpty) {
      _results = [];
      _hasSearched = false;
      _isSearching = false;
      _lastQuery = '';
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _hasSearched = true;
    _lastQuery = q;
    _searchError = null;
    notifyListeners();

    try {
      final found = await _quoteRepository.searchQuotes(q);
      if (token != _searchToken) return;
      _results = found;
    } catch (e) {
      if (token != _searchToken) return;
      _results = [];
      _searchError = 'Search failed. Please try again.';
      debugPrint('Error searching quotes: $e');
    } finally {
      if (token == _searchToken) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  /// Mengembalikan true hanya jika quote benar-benar masuk ke database.
  Future<bool> addQuote(String bookId, String text, int pageNumber, List<String> tags) async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return false;
    }

    try {
      await _quoteRepository.saveQuote(userId, bookId, text, pageNumber, tags);
    } catch (e) {
      _errorMessage = 'Failed to save quote: $e';
      debugPrint('Error saving quote: $e');
      notifyListeners();
      return false;
    }
    await loadUserQuotes(silent: true);
    return true;
  }

  /// Hapus kutipan milik sendiri. Tampilan langsung berubah; dikembalikan jika gagal.
  Future<bool> removeQuote(String quoteId) async {
    final mineBefore = List<QuoteEntity>.of(_userQuotes);
    final resultsBefore = List<QuoteEntity>.of(_results);

    _userQuotes.removeWhere((q) => q.id == quoteId);
    _results.removeWhere((q) => q.id == quoteId);
    notifyListeners();

    try {
      await _quoteRepository.deleteQuote(quoteId);
      return true;
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      _userQuotes = mineBefore;
      _results = resultsBefore;
      _errorMessage = 'Could not delete the quote. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
