class Review {
  final String id;
  final String userId;
  final String bookId;
  final int rating;
  final String reviewText;
  final DateTime createdAt;
  final String? username; // For joined profiles

  Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.username,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
    );
  }
}
