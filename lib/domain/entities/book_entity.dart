import 'package:equatable/equatable.dart';

class BookEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String category;
  final double rating;
  final String description;
  final String isbn;
  final double averageRating;
  final int totalReviews;


  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.category,
    required this.rating,
    required this.description,
    required this.isbn,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  List<Object?> get props => [id, title, author, coverUrl, category, rating, description, isbn, averageRating, totalReviews];
}
