import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/book_group.dart';

class GroupViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<BookGroup> _groups = [];
  bool _isLoading = false;

  List<BookGroup> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      _groups = await _bookService.getGroups();
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description, String? bookId) async {
    try {
      await _bookService.createGroup(
        name: name,
        description: description,
        bookId: bookId,
      );
      await loadGroups();
      return true;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return false;
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      await _bookService.joinGroup(groupId);
      return true;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return false;
    }
  }
}
