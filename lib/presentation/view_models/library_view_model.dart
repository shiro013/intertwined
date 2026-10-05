import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/book_entity.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../../domain/repositories/book_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final BookRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<LibraryItemEntity> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  // Stats (dipakai ProfileScreen)
  int _totalBooksRead = 0;
  int _totalQuotesSaved = 0;
  int _totalGroupsJoined = 0;

  LibraryViewModel(this._repository);

  List<LibraryItemEntity> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  int get totalBooksRead => _totalBooksRead;
  int get totalQuotesSaved => _totalQuotesSaved;
  int get totalGroupsJoined => _totalGroupsJoined;

  /// Tab "All": semua buku (punya status baca dan/atau di-bookmark).
  List<LibraryItemEntity> get allItems => _items;
  List<LibraryItemEntity> get wantToReadItems => _byStatus(BookReadingStatus.wantToRead);
  List<LibraryItemEntity> get readingItems => _byStatus(BookReadingStatus.reading);
  List<LibraryItemEntity> get finishedItems => _byStatus(BookReadingStatus.finished);
  List<LibraryItemEntity> get bookmarkedItems =>
      _items.where((i) => i.isBookmarked).toList();

  // Kompatibilitas dengan kode lama
  List<BookEntity> get myBooks => _items.map((i) => i.book).toList();

  List<LibraryItemEntity> _byStatus(BookReadingStatus status) =>
      _items.where((i) => i.status == status).toList();

  /// [silent] = refresh di belakang layar (tanpa spinner layar penuh), dipakai
  /// setelah user mengubah status/bookmark di halaman buku dan saat pull-to-refresh.
  Future<void> loadLibrary({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _items = [];
        _totalBooksRead = 0;
        _totalQuotesSaved = 0;
        _totalGroupsJoined = 0;
        return;
      }

      final results = await Future.wait<Object>([
        _repository.getLibrary(),
        _supabase.from('quotes').select('id').eq('user_id', user.id),
        _supabase.from('group_members').select('group_id').eq('user_id', user.id),
      ]);

      _items = results[0] as List<LibraryItemEntity>;
      _totalBooksRead =
          _items.where((i) => i.status == BookReadingStatus.finished).length;
      _totalQuotesSaved = (results[1] as List).length;
      _totalGroupsJoined = (results[2] as List).length;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load library: $e';
      debugPrint('Error loading library: $e');
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }
}
