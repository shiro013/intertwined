import 'package:equatable/equatable.dart';

enum BookReadingStatus {
  wantToRead,
  reading,
  finished,
}

class UserBookInteractionEntity extends Equatable {
  final String userId;
  final String bookId;
  final int rating; // 1-5
  final String review;
  final BookReadingStatus status;
  final bool isBookmarked;
  final int currentPage;
  final DateTime? lastReadAt;

  const UserBookInteractionEntity({
    required this.userId,
    required this.bookId,
    this.rating = 0,
    this.review = '',
    this.status = BookReadingStatus.wantToRead,
    this.isBookmarked = false,
    this.currentPage = 0,
    this.lastReadAt,
  });

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
