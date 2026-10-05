import '../../domain/entities/book_entity.dart';

class BookModel extends BookEntity {
  const BookModel({
    required super.id,
    required super.title,
    required super.author,
    required super.coverUrl,
    required super.category,
    required super.rating,
    required super.description,
    required super.isbn,
    required super.averageRating,
    required super.totalReviews,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      coverUrl: json['coverUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Unknown',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? 'No description available.',
      isbn: json['isbn']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }

  /// Mapping untuk baris tabel `books` di Supabase.
  /// PENTING: `id` pada entity = `external_id` (Google Books volume id),
  /// BUKAN kolom uuid `id`. Semua layar memakai ID yang sama ini.
  factory BookModel.fromSupabase(Map<String, dynamic> row, {double rating = 0.0}) {
    return BookModel(
      id: row['external_id']?.toString() ?? '',
      title: row['title']?.toString() ?? 'Unknown Title',
      author: row['author']?.toString() ?? 'Unknown Author',
      coverUrl: normalizeCoverUrl(row['cover_url']?.toString()),
      category: row['genre']?.toString() ?? 'Unknown',
      rating: rating,
      description: row['synopsis']?.toString() ?? 'No description available.',
      isbn: '',
      averageRating: 0.0,
      totalReviews: 0,
    );
  }

  /// Google Books mengembalikan http:// dan parameter `edge=curl` (efek
  /// lipatan halaman). Paksa https dan buang efek lipatan.
  static String normalizeCoverUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    return url
        .trim()
        .replaceFirst('http://', 'https://')
        .replaceAll('&edge=curl', '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'category': category,
      'rating': rating,
      'description': description,
      'isbn': isbn,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}
