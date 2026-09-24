import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../core/config.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query) async {
    final url = Uri.parse('$_baseUrl?q=$query&printtype=books&key=${AppConfig.googleBooksApiKey}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) => _mapToBook(item)).toList();
      } else {
        throw Exception('Failed to load books from Google Books API');
      }
    } catch (e) {
      debugPrint('GoogleBooksService Error: $e');
      return [];
    }
  }

  Future<List<Book>> getTrendingBooks() async {
    // Google Books API doesn't have a direct 'trending' endpoint,
    // so we use a generic high-quality search query for popular books
    return await searchBooks('bestsellers 2024');
  }

  Future<Book?> getBookDetails(String bookId) async {
    final url = Uri.parse('$_baseUrl/$bookId?key=${AppConfig.googleBooksApiKey}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _mapToBook(data);
      }
    } catch (e) {
      debugPrint('GoogleBooksService getDetails Error: $e');
    }
    return null;
  }

  Book _mapToBook(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] ?? {};
    final id = item['id'] ?? '';
    final title = volumeInfo['title'] ?? 'Unknown Title';

    final List<dynamic> authors = volumeInfo['authors'] ?? [];
    final author = authors.isNotEmpty ? authors.join(', ') : 'Unknown Author';

    String? isbn;
    final List<dynamic> identifiers = volumeInfo['industryIdentifiers'] ?? [];
    for (var idObj in identifiers) {
      if (idObj['type'] == 'ISBN_13') {
        isbn = idObj['identifier'];
        break;
      }
    }
    if (isbn == null && identifiers.isNotEmpty) {
      isbn = identifiers[0]['identifier'];
    }

    String? coverUrl;
    final imageLinks = volumeInfo['imageLinks'];
    if (imageLinks != null && imageLinks['thumbnail'] != null) {
      coverUrl = imageLinks['thumbnail'].toString().replaceFirst('http://', 'https://');
    }

    final categories = volumeInfo['categories'] ?? [];
    final genre = categories.isNotEmpty ? categories.join(', ') : null;

    return Book(
      id: id,
      title: title,
      author: author,
      isbn: isbn,
      description: volumeInfo['description'],
      coverUrl: coverUrl,
      genre: genre,
      synopsis: volumeInfo['description'],
    );
  }
}
