import 'package:flutter/material.dart';
import '../services/book_service.dart';

class FeedItem {
  final String type; // 'quote' or 'review'
  final dynamic data; // Quote or Review
  final String createdAt;

  FeedItem({
    required this.type,
    required this.data,
    required this.createdAt,
  });
}

class FeedViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<FeedItem> _feedItems = [];
  bool _isLoading = false;

  List<FeedItem> get feedItems => _feedItems;
  bool get isLoading => _isLoading;

  Future<void> loadFeed() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rawFeed = await _bookService.getGlobalFeed();
      _feedItems = rawFeed.map((item) {
        return FeedItem(
          type: item['type'] as String,
          data: item['data'], // Already cast to Quote or Review in BookService
          createdAt: item['created_at'] as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeed() async {
    await loadFeed();
  }
}
