import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/book_review_entity.dart';
import 'like_button.dart';
import 'user_avatar.dart';

/// Daftar review semua pembaca untuk sebuah buku.
class BookReviewsSection extends StatefulWidget {
  final List<BookReviewEntity> reviews;
  final String? currentUserId;
  final bool isLoading;
  final ValueChanged<String> onToggleLike;

  const BookReviewsSection({
    super.key,
    required this.reviews,
    required this.currentUserId,
    required this.isLoading,
    required this.onToggleLike,
  });

  @override
  State<BookReviewsSection> createState() => _BookReviewsSectionState();
}

class _BookReviewsSectionState extends State<BookReviewsSection> {
  static const int _collapsedCount = 3;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    final visible = _showAll ? reviews : reviews.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reviews.isEmpty ? 'Reader Reviews' : 'Reader Reviews (${reviews.length})',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Text(
            widget.isLoading
                ? 'Loading reviews…'
                : 'No reviews yet. Be the first to rate this book!',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else ...[
          for (final r in visible)
            _ReviewTile(
              review: r,
              isMine: r.userId == widget.currentUserId,
              onLike: () => widget.onToggleLike(r.id),
            ),
          if (reviews.length > _collapsedCount)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Show less' : 'Show all ${reviews.length} reviews',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final BookReviewEntity review;
  final bool isMine;
  final VoidCallback onLike;

  const _ReviewTile({
    required this.review,
    required this.isMine,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.surfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                username: review.username,
                avatarUrl: review.avatarUrl,
                radius: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.username ?? 'Unknown User',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '(you)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo(review.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              LikeButton(
                liked: review.likedByMe,
                count: review.likeCount,
                onTap: onLike,
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
