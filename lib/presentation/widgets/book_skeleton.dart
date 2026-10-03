import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BookSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const BookSkeleton({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceVariant,
              AppColors.surface,
            ],
            stops: const [0.1, 0.5, 0.9],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcATop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Placeholder
            Container(
              height: height * 0.65,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            // Text Placeholders
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: width * 0.7,
                    color: AppColors.surfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: width * 0.4,
                    color: AppColors.surfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 12,
                        width: 40,
                        color: AppColors.surfaceVariant,
                      ),
                      Container(
                        height: 12,
                        width: 20,
                        color: AppColors.surfaceVariant,
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