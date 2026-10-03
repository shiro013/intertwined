import 'package:equatable/equatable.dart';

class FeedActivityEntity extends Equatable {
  final String id;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final String activityType; // 'share_quote', 'post_review', 'repost'
  final String? bookId;
  final String? bookTitle;
  final String? bookCoverUrl;
  final String? originalContentId;
  final String? contentPreview;
  final DateTime createdAt;

  const FeedActivityEntity({
    required this.id,
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.activityType,
    this.bookId,
    this.bookTitle,
    this.bookCoverUrl,
    this.originalContentId,
    this.contentPreview,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, username, activityType, bookId, createdAt];
}
