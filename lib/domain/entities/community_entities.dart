class LikeInfo {
  final int count;
  final bool likedByMe;

  const LikeInfo({this.count = 0, this.likedByMe = false});
}

class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final int memberCount;

  /// uuid di tabel `books` (BUKAN Google external id).
  final String? relatedBookId;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.memberCount,
    this.relatedBookId,
  });

  CommunityGroup copyWith({int? memberCount}) {
    return CommunityGroup(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
      memberCount: memberCount ?? this.memberCount,
      relatedBookId: relatedBookId,
    );
  }
}

class CommunityDiscussion {
  final String id;
  final String groupId;
  final String? groupName;
  final String userId;
  final String? username;
  final String content;
  final DateTime createdAt;
  final int replyCount;
  final int likeCount;
  final bool likedByMe;

  CommunityDiscussion({
    required this.id,
    required this.groupId,
    this.groupName,
    required this.userId,
    this.username,
    required this.content,
    required this.createdAt,
    required this.replyCount,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  CommunityDiscussion copyWith({
    int? replyCount,
    int? likeCount,
    bool? likedByMe,
  }) {
    return CommunityDiscussion(
      id: id,
      groupId: groupId,
      groupName: groupName,
      userId: userId,
      username: username,
      content: content,
      createdAt: createdAt,
      replyCount: replyCount ?? this.replyCount,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
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
