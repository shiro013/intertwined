
class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final int memberCount;
  final String? relatedBookId;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.memberCount,
    this.relatedBookId,
  });
}

class CommunityDiscussion {
  final String id;
  final String groupId;
  final String userId;
  final String? username;
  final String content;
  final DateTime createdAt;
  final int replyCount;

  CommunityDiscussion({
    required this.id,
    required this.groupId,
    required this.userId,
    this.username,
    required this.content,
    required this.createdAt,
    required this.replyCount,
  });
}

class CommunityComment {
  final String id;
  final String discussionId;
  final String userId;
  final String? username;
  final String content;
  final DateTime createdAt;
  final String? parentCommentId;

  CommunityComment({
    required this.id,
    required this.discussionId,
    required this.userId,
    this.username,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
  });
}
