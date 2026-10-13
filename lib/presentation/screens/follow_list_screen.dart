import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/follow_repository_impl.dart';
import '../../domain/entities/follow_entities.dart';
import '../../domain/repositories/follow_repository.dart';
import '../navigation/profile_navigation.dart';
import '../widgets/user_list_tile.dart';

enum FollowListMode { followers, following }

/// Daftar orang yang mengikuti [userId] (followers) atau diikuti [userId] (following).
class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowListMode mode;

  const FollowListScreen({super.key, required this.userId, required this.mode});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FollowRepository _repository = FollowRepositoryImpl();

  List<UserSummary> _people = [];
  bool _isLoading = true;
  String? _error;

  bool get _isFollowers => widget.mode == FollowListMode.followers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final people = _isFollowers
          ? await _repository.getFollowers(widget.userId)
          : await _repository.getFollowing(widget.userId);
      if (!mounted) return;
      setState(() => _people = people);
    } catch (e) {
      debugPrint('Load follow list failed: $e');
      if (!mounted) return;
      setState(() => _error = 'Could not load this list. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          _isFollowers ? 'Followers' : 'Following',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _isFollowers
                ? 'No followers yet.'
                : 'Not following anyone yet. Use "Find Readers" to discover people.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _people.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.surface),
        itemBuilder: (context, index) {
          final person = _people[index];
          return UserListTile(
            person: person,
            onTap: () => openUserProfile(context, person.id),
          );
        },
      ),
    );
  }
}
