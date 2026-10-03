import 'package:equatable/equatable.dart';

class QuoteEntity extends Equatable {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String? username; // penulis quote (jika diambil dengan join profiles)
  final String text;
  final int? pageNumber;
  final List<String> tags;
  final DateTime createdAt;

  const QuoteEntity({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    this.username,
    required this.text,
    this.pageNumber,
    this.tags = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, bookId, text, createdAt];
}
