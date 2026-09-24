enum ReadingStatusType {
  wantToRead,
  reading,
  finished;

  static ReadingStatusType fromString(String value) {
    switch (value) {
      case 'want_to_read':
        return ReadingStatusType.wantToRead;
      case 'reading':
        return ReadingStatusType.reading;
      case 'finished':
        return ReadingStatusType.finished;
      default:
        throw ArgumentError('Unknown reading status: $value');
    }
  }

  String toDbValue() {
    switch (this) {
      case ReadingStatusType.wantToRead:
        return 'want_to_read';
      case ReadingStatusType.reading:
        return 'reading';
      case ReadingStatusType.finished:
        return 'finished';
    }
  }
}

class ReadingStatus {
  final String id;
  final String userId;
  final String bookId;
  final ReadingStatusType status;
  final int? currentPage;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime updatedAt;

  const ReadingStatus({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.currentPage,
    this.startedAt,
    this.finishedAt,
    required this.updatedAt,
  });

  factory ReadingStatus.fromJson(Map<String, dynamic> json) {
    return ReadingStatus(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      status: ReadingStatusType.fromString(json['status'] as String),
      currentPage: json['current_page'] as int?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'book_id': bookId,
      'status': status.toDbValue(),
      if (currentPage != null) 'current_page': currentPage,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
    };
  }

  ReadingStatus copyWith({
    ReadingStatusType? status,
    int? currentPage,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return ReadingStatus(
      id: id,
      userId: userId,
      bookId: bookId,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      updatedAt: updatedAt,
    );
  }
}
