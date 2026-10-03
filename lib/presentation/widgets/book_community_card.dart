import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/community_entities.dart';
import 'user_avatar.dart';

/// Kartu "Community" di halaman buku: info klub buku + 2 diskusi terbaru.
class BookCommunityCard extends StatelessWidget {
  final CommunityGroup? group;
  final List<CommunityDiscussion> discussions;
  final bool isLoading;
  final VoidCallback onOpen;

  const BookCommunityCard({
    super.key,
    required this.group,
    required this.discussions,
    required this.isLoading,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final g = group;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Community',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: Text(
                  g == null ? 'Start Discussion' : 'Join Discussion',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (g != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${g.memberCount} ${g.memberCount == 1 ? 'member' : 'members'}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          if (isLoading && g == null)
            const Text(
              'Checking the book club…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else if (discussions.isEmpty)
            Text(
              g == null
                  ? 'No one has started a conversation about this book yet. Be the first!'
                  : 'No posts in this club yet. Start the conversation!',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            for (final d in discussions) _PreviewRow(discussion: d, onTap: onOpen),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final CommunityDiscussion discussion;
  final VoidCallback onTap;

  const _PreviewRow({required this.discussion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(username: discussion.username, radius: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          discussion.username ?? 'Unknown User',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(discussion.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discussion.content,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${discussion.likeCount}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${discussion.replyCount}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
