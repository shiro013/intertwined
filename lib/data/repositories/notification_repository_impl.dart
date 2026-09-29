import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((item) {
        return NotificationEntity(
          id: item['id'],
          userId: item['user_id'],
          type: NotificationType.values.firstWhere(
            (e) => e.name == item['type'],
            orElse: () => NotificationType.genreAlert,
          ),
          content: item['content'],
          targetId: item['target_id'],
          createdAt: DateTime.parse(item['created_at']),
          isRead: item['is_read'] ?? false,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }

  @override
  Future<void> createNotification(String userId, NotificationType type, String content, {String? targetId}) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': type.name,
      'content': content,
      'target_id': targetId,
      'is_read': false,
    });
  }
}
