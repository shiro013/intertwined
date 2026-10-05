import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avatar bulat: foto profil jika ada, kalau tidak huruf pertama username.
class UserAvatar extends StatelessWidget {
  final String? username;
  final String? avatarUrl;
  final double radius;

  const UserAvatar({
    super.key,
    this.username,
    this.avatarUrl,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final name = (username ?? '').trim();
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: hasImage ? NetworkImage(avatarUrl!.trim()) : null,
      // cegah exception tak tertangani kalau URL foto rusak
      onBackgroundImageError: hasImage ? (_, _) {} : null,
      child: hasImage
          ? null
          : Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.9,
              ),
            ),
    );
  }
}
