import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/feed_activity_entity.dart';
import 'user_avatar.dart';

import '../navigation/profile_navigation.dart';
/// Satu item "Community Activity": kutipan, review, diskusi, atau repost.
class FeedActivityCard extends StatelessWidget {
  final FeedActivityEntity activity;
  final VoidCallback? onTap;

  /// null = tombol Repost tidak ditampilkan.
  final VoidCallback? onRepost;

  const FeedActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onRepost,
  });

  String get _label {
    final book = activity.bookTitle ?? 'a book';
    final original = activity.originalAuthor == null ? '' : ' by @${activity.originalAuthor}';
    switch (activity.activityType) {
      case 'share_quote':
        return 'shared a quote from $book';
      case 'post_review':
        return 'reviewed $book';
      case 'post_discussion':
        return 'posted in ${activity.groupName ?? 'a club'}';
      case 'repost_quote':
        return 'reposted a quote$original from $book';
      case 'repost_review':
        return 'reposted a review$original of $book';
      default:
        return activity.activityType;
    }
  }

  IconData get _icon {
    switch (activity.activityType) {
      case 'share_quote':
      case 'repost_quote':
        return Icons.format_quote;
      case 'post_review':
      case 'repost_review':
        return Icons.star_outline;
      case 'post_discussion':
        return Icons.forum_outlined;
      default:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQuote = activity.activityType.endsWith('quote');
    final preview = activity.contentPreview ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => openUserProfile(context, activity.userId),
                      child: UserAvatar(
                        username: activity.username,
                        avatarUrl: activity.avatarUrl,
                        radius: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => openUserProfile(context, activity.userId),
                            child: Text(
                              activity.username ?? 'Unknown User',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(_icon, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _label,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(activity.createdAt),
                      style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                    ),
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    preview,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (onRepost != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onRepost,
                      icon: const Icon(Icons.repeat, size: 16, color: AppColors.textSecondary),
                      label: const Text(
                        'Repost',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
