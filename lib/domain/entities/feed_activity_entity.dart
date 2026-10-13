import 'package:equatable/equatable.dart';

import 'community_entities.dart';

class FeedActivityEntity extends Equatable {
  final String id;
  final String userId;
  final String? username;
  final String? avatarUrl;

  /// 'share_quote', 'post_review', 'post_discussion', 'repost_quote', 'repost_review'
  final String activityType;
  final String? bookId; // uuid di tabel books
  final String? bookExternalId; // id Google Books (untuk membuka halaman buku)
  final String? bookTitle;
  final String? bookCoverUrl;
  final String? originalContentId; // id kutipan/review asli
  final String? contentPreview;
  final String? originalAuthor; // username penulis asli (khusus repost)
  final String? groupName; // klub (khusus diskusi)
  final CommunityDiscussion? discussion; // diskusi lengkap (khusus post_discussion)
  final DateTime createdAt;

  const FeedActivityEntity({
    required this.id,
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.activityType,
    this.bookId,
    this.bookExternalId,
    this.bookTitle,
    this.bookCoverUrl,
    this.originalContentId,
    this.contentPreview,
    this.originalAuthor,
    this.groupName,
    this.discussion,
    required this.createdAt,
  });

  bool get isRepost => activityType.startsWith('repost_');

  /// Hanya kutipan/review ASLI (bukan repost) yang bisa di-repost.
  bool get canBeReposted =>
      (activityType == 'share_quote' || activityType == 'post_review') &&
      originalContentId != null;

  @override
  List<Object?> get props => [id, userId, username, activityType, bookId, createdAt];
}
