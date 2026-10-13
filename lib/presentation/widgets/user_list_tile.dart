import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/follow_entities.dart';
import 'user_avatar.dart';

/// Satu baris pengguna (daftar followers / following / hasil pencarian).
class UserListTile extends StatelessWidget {
  final UserSummary person;
  final VoidCallback onTap;

  const UserListTile({super.key, required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fullName = (person.fullName ?? '').trim();
    final bio = (person.bio ?? '').trim();
    final subtitle = fullName.isNotEmpty ? fullName : bio;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: UserAvatar(
        username: person.username,
        avatarUrl: person.avatarUrl,
        radius: 22,
      ),
      title: Text(
        '@${person.username}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
    );
  }
}
