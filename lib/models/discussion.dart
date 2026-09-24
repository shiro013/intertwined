class Discussion {
  final String id;
  final String groupId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? username; // For joined profiles

  Discussion({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.username,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Discussion(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
    );
  }
}
