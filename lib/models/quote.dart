class Quote {
  final String id;
  final String userId;
  final String bookId;
  final String quoteText;
  final int? pageNumber;
  final List<String>? tags;
  final DateTime createdAt;
  final String? username; // For joined profiles

  Quote({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quoteText,
    this.pageNumber,
    this.tags,
    required this.createdAt,
    this.username,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Quote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      quoteText: json['quote_text'] as String,
      pageNumber: json['page_number'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
    );
  }
}
