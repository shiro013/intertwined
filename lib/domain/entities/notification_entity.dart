import 'package:flutter/material.dart';

enum NotificationType {
  reply,
  like,
  communityJoin,
  genreAlert,
}

class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String content;
  final String? targetId;
  final DateTime createdAt;
  final bool isRead;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.targetId,
    required this.createdAt,
    required this.isRead,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? content,
    String? targetId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
