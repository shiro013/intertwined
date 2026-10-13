import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/notification_entity.dart';
import '../view_models/community_view_model.dart';
import '../view_models/notifications_view_model.dart';
import 'discussion_detail_screen.dart';
import 'discussion_thread_screen.dart';

import 'user_profile_screen.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().loadNotifications();
    });
  }

  /// Tandai dibaca, lalu buka tujuannya: diskusi (balasan / aktivitas klub) atau klub.
  Future<void> _open(NotificationEntity notification) async {
    final notifications = context.read<NotificationsViewModel>();
    final community = context.read<CommunityViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    notifications.markAsRead(notification.id);

    final targetId = notification.targetId;
    if (targetId == null) return;

    void unavailable(String what) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$what is no longer available.')));
    }

    switch (notification.type) {
      case NotificationType.reply:
      case NotificationType.clubActivity:
        {
          final discussion = await community.loadDiscussion(targetId);
          if (!mounted) return;
          if (discussion == null) {
            unavailable('This discussion');
            return;
          }
          navigator.push(
            MaterialPageRoute(builder: (_) => DiscussionDetailScreen(discussion: discussion)),
          );
        }
      case NotificationType.communityJoin:
        {
          final group = await community.loadGroup(targetId);
          if (!mounted) return;
          if (group == null) {
            unavailable('This club');
            return;
          }
          navigator.push(
            MaterialPageRoute(builder: (_) => DiscussionThreadScreen(group: group)),
          );
        }
            case NotificationType.newFollower:
        navigator.push(
          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: targetId)),
        );
      case NotificationType.like:
      case NotificationType.genreAlert:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();
    final notifications = viewModel.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        actions: [
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: () => viewModel.markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: viewModel.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => viewModel.loadNotifications(silent: true),
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 420,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 64,
                                    color: AppColors.surfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    viewModel.errorMessage ??
                                        'No notifications yet.\nReplies to your comments and new posts in your clubs show up here.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationTile(
                          notification: notification,
                          onTap: () => _open(notification),
                        );
                      },
                    ),
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? AppColors.background : AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notification.type),
          radius: 14,
          child: Icon(_getTypeIcon(notification.type), size: 14, color: Colors.white),
        ),
        title: Text(
          notification.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          timeAgo(notification.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        onTap: onTap,
        trailing: !notification.isRead
            ? const CircleAvatar(radius: 4, backgroundColor: AppColors.primary)
            : null,
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reply:
        return Colors.blue;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.communityJoin:
        return Colors.green;
      case NotificationType.clubActivity:
        return Colors.purple;
            case NotificationType.genreAlert:
        return Colors.orange;
      case NotificationType.newFollower:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.communityJoin:
        return Icons.group_add;
      case NotificationType.clubActivity:
        return Icons.forum;
            case NotificationType.genreAlert:
        return Icons.notifications_active;
      case NotificationType.newFollower:
        return Icons.person_add_alt_1;
    }
  }
}
