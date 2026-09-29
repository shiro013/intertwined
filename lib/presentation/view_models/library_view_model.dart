import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/book_model.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/book_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final BookRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Real Stats
  int get totalBooksRead => _totalBooksRead;
  int get totalQuotesSaved => _totalQuotesSaved;
  int get totalGroupsJoined => _totalGroupsJoined;

  // Filtered lists based on interaction status
  List<BookEntity> get readingBooks => []; // Implementation would require a combined entity
  List<BookEntity> get finishedBooks => [];
  List<BookEntity> get wantToReadBooks => [];

  Future<void> loadLibrary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Ambil buku + status baca sekaligus (join ke tabel books)
      final rows = await _supabase
          .from('reading_status')
          .select('status, books(*)')
          .eq('user_id', user.id);

      _myBooks = [];
      for (final row in rows as List) {
        final b = row['books'] as Map<String, dynamic>?;
        if (b != null) _myBooks.add(BookModel.fromSupabase(b));
      }

      // 3. Calculate Statistics
      final readResponse = await _supabase
          .from('reading_status')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Finished');

      final quoteResponse = await _supabase
          .from('quotes')
          .select()
          .eq('user_id', user.id);

      final groupResponse = await _supabase
          .from('group_members')
          .select()
          .eq('user_id', user.id);

      _totalBooksRead = readResponse.length;
      _totalQuotesSaved = quoteResponse.length;
      _totalGroupsJoined = groupResponse.length;

    } catch (e) {
      _errorMessage = 'Failed to load library: $e';
      debugPrint('Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
