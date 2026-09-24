class BookGroup {
  final String id;
  final String name;
  final String description;
  final String? bookId;
  final String createdBy;
  final DateTime createdAt;
  final String? bookTitle; // For joined books

  BookGroup({
    required this.id,
    required this.name,
    required this.description,
    this.bookId,
    required this.createdBy,
    required this.createdAt,
    this.bookTitle,
  });

  factory BookGroup.fromJson(Map<String, dynamic> json) {
    final book = json['books'] as Map<String, dynamic>?;
    return BookGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      bookId: json['book_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookTitle: book?['title'] as String?,
    );
  }
}
