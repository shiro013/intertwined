import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/quote_entity.dart';

import '../navigation/profile_navigation.dart';
/// Kartu satu kutipan. Ketuk kartu = buka bukunya; ketuk tag = [onTagTap].
class QuoteCard extends StatelessWidget {
  final QuoteEntity quote;
  final bool showAuthor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare; // bagikan kutipan MILIK SENDIRI ke feed
  final VoidCallback? onRepost; // repost kutipan orang lain
  final ValueChanged<String>? onTagTap;
  final String? activeTag;

  const QuoteCard({
    super.key,
    required this.quote,
    this.showAuthor = false,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.onRepost,
    this.onTagTap,
    this.activeTag,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      
      if (quote.pageNumber != null) 'p. ${quote.pageNumber}',
      timeAgo(quote.createdAt),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      // Border non-uniform (hanya kiri) tidak boleh dipadukan dengan borderRadius.
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.45,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
          if (showAuthor && (quote.username ?? '').isNotEmpty) ...[
            GestureDetector(
              onTap: () => openUserProfile(context, quote.userId),
              child: Text(
                '@${quote.username}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            quote.bookTitle,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (quote.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in quote.tags)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: onTagTap == null ? null : () => onTagTap!(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: (activeTag != null &&
                                              activeTag!.toLowerCase() == tag.toLowerCase())
                                          ? 0.45
                                          : 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 11),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onShare != null || onRepost != null || onDelete != null)
                  Column(
                    children: [
                      if (onShare != null)
                        IconButton(
                          tooltip: 'Share to feed',
                          icon: const Icon(Icons.ios_share, color: AppColors.textSecondary, size: 20),
                          onPressed: onShare,
                        ),
                      if (onRepost != null)
                        IconButton(
                          tooltip: 'Repost to your feed',
                          icon: const Icon(Icons.repeat, color: AppColors.textSecondary, size: 20),
                          onPressed: onRepost,
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete quote',
                          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
