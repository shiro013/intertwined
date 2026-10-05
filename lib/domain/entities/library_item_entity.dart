import 'package:equatable/equatable.dart';

import 'book_entity.dart';
import 'user_book_interaction_entity.dart';

/// Satu buku di library user: buku + status baca + apakah di-bookmark.
/// `book.rating` di sini berisi rating milik user sendiri (0 jika belum).
class LibraryItemEntity extends Equatable {
  final BookEntity book;
  final BookReadingStatus? status; // null = hanya di-bookmark
  final bool isBookmarked;

  const LibraryItemEntity({
    required this.book,
    this.status,
    this.isBookmarked = false,
  });

  @override
  List<Object?> get props => [book, status, isBookmarked];
}
