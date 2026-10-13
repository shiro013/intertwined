import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tombol like kecil: ikon + jumlah. [onTap] null = hanya tampilan.
class LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback? onTap;

  const LikeButton({
    super.key,
    required this.liked,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = liked ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
