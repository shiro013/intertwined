import '../models/book.dart';
import '../models/reading_status.dart';

class LibraryItem {
  final ReadingStatus status;
  final Book book;

  LibraryItem({
    required this.status,
    required this.book,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      status: ReadingStatus.fromJson(json),
      book: Book.fromJson(json['books'] as Map<String, dynamic>),
    );
  }
}
