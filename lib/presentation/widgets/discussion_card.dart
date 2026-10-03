import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/community_entities.dart';
import 'like_button.dart';
import 'user_avatar.dart';

class DiscussionCard extends StatelessWidget {
  final CommunityDiscussion discussion;
  final VoidCallback onTap;
  final VoidCallback? onLike;

  /// Tampilkan nama klub di kartu (berguna di feed gabungan, tidak perlu di dalam klub).
  final bool showGroup;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.onTap,
    this.onLike,
    this.showGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final groupName = discussion.groupName;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(username: discussion.username, radius: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion.username ?? 'Unknown User',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showGroup && groupName != null && groupName.isNotEmpty)
                          Text(
                            'in $groupName',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    timeAgo(discussion.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                discussion.content,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  LikeButton(
                    liked: discussion.likedByMe,
                    count: discussion.likeCount,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${discussion.replyCount}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
