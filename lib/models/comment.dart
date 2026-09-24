class Comment {
  final String id;
  final String discussionId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? username; // Joined from profiles

  Comment({
    required this.id,
    required this.discussionId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.username,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'] as String,
      discussionId: json['discussion_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
    );
  }
}
