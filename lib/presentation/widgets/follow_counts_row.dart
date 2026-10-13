import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/follow_repository_impl.dart';
import '../../domain/repositories/follow_repository.dart';
import '../screens/follow_list_screen.dart';
import '../view_models/notifications_view_model.dart';

/// Dua angka "Followers | Following" di profil sendiri; ketuk untuk melihat daftarnya.
/// Angka dimuat ulang saat ada notifikasi baru (mis. seseorang baru mengikuti kita).
class FollowCountsRow extends StatefulWidget {
  final String userId;

  const FollowCountsRow({super.key, required this.userId});

  @override
  State<FollowCountsRow> createState() => _FollowCountsRowState();
}

class _FollowCountsRowState extends State<FollowCountsRow> {
  final FollowRepository _repository = FollowRepositoryImpl();

  int _followers = 0;
  int _following = 0;
  int _notificationMarker = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repository.getStats(widget.userId);
    if (!mounted) return;
    setState(() {
      _followers = stats.followers;
      _following = stats.following;
    });
  }

  Future<void> _open(FollowListMode mode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(userId: widget.userId, mode: mode),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final marker = context.watch<NotificationsViewModel>().notifications.length;
    if (_notificationMarker != marker) {
      final isFirstBuild = _notificationMarker == -1;
      _notificationMarker = marker;
      if (!isFirstBuild) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load();
        });
      }
    }

    return Row(
      children: [
        Expanded(
          child: _CountTile(
            label: 'Followers',
            value: _followers,
            onTap: () => _open(FollowListMode.followers),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CountTile(
            label: 'Following',
            value: _following,
            onTap: () => _open(FollowListMode.following),
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;

  const _CountTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
