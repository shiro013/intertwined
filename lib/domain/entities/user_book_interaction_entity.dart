import 'package:equatable/equatable.dart';

enum BookReadingStatus {
  wantToRead,
  reading,
  finished,
}

class UserBookInteractionEntity extends Equatable {
  final String userId;
  final String bookId;
  final int rating; // 1-5, 0 = belum dirating
  final String review;

  /// `null` = buku ini belum ada di library user (belum punya baris reading_status).
  final BookReadingStatus? status;
  final bool isBookmarked;
  final int currentPage;
  final DateTime? lastReadAt;

  const UserBookInteractionEntity({
    required this.userId,
    required this.bookId,
    this.rating = 0,
    this.review = '',
    this.status,
    this.isBookmarked = false,
    this.currentPage = 0,
    this.lastReadAt,
  });

  bool get inLibrary => status != null;

  UserBookInteractionEntity copyWith({
    String? userId,
    String? bookId,
    int? rating,
    String? review,
    BookReadingStatus? status,
    bool? isBookmarked,
    int? currentPage,
    DateTime? lastReadAt,
  }) {
    return UserBookInteractionEntity(
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      status: status ?? this.status,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      currentPage: currentPage ?? this.currentPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  List<Object?> get props => [userId, bookId, rating, review, status, isBookmarked, currentPage, lastReadAt];
}
