class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverUrl;
  final String? genre;
  final String? synopsis;
  final DateTime? cachedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverUrl,
    this.genre,
    this.synopsis,
    this.cachedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String?,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      genre: json['genre'] as String?,
      synopsis: json['synopsis'] as String?,
      cachedAt: json['cached_at'] == null
          ? null
          : DateTime.parse(json['cached_at'] as String),
    );
  }
}
