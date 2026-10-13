import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/book_entity.dart';
import 'safe_network_image.dart';

class BookCoverWidget extends StatelessWidget {
  final BookEntity book;
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const BookCoverWidget({
    super.key,
    required this.book,
    required this.height,
    required this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SafeNetworkImage(
        url: book.coverUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        fallback: _buildElegantFallback(),
      ),
    );
  }

  Widget _buildElegantFallback() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.background,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
