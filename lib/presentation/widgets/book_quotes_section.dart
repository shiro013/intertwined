import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/quote_entity.dart';

/// Daftar quote favorit untuk sebuah buku. Quote milik sendiri bisa dihapus.
class BookQuotesSection extends StatelessWidget {
  final List<QuoteEntity> quotes;
  final String? currentUserId;
  final bool isLoading;
  final ValueChanged<String> onDelete;

  const BookQuotesSection({
    super.key,
    required this.quotes,
    required this.currentUserId,
    required this.isLoading,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context, QuoteEntity quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete quote?', style: TextStyle(color: AppColors.primary)),
        content: const Text(
          'This quote will be removed from your collection.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(quote.id);
  }

  String _meta(QuoteEntity q) => [
        if (q.username != null && q.username!.isNotEmpty) q.username!,
        if (q.pageNumber != null) 'p. ${q.pageNumber}',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul + tombol "Save Quote" dirender oleh BookDetailScreen.
        if (quotes.isEmpty)
          Text(
            isLoading
                ? 'Loading quotes…'
                : 'No quotes saved from this book yet.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          for (final q in quotes)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              // Border non-uniform (hanya kiri) tidak boleh dikombinasikan dengan
              // borderRadius -> Flutter akan assert. Sudut dibiarkan tegas ala blockquote.
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        if (_meta(q).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _meta(q),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                        if (q.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in q.tags)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (q.userId == currentUserId)
                    IconButton(
                      tooltip: 'Delete quote',
                      icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                      onPressed: () => _confirmDelete(context, q),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
