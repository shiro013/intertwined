import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/follow_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/quote_repository_impl.dart';
import '../../domain/entities/quote_entity.dart';
import '../view_models/user_profile_view_model.dart';
import '../widgets/quote_card.dart';
import '../widgets/user_avatar.dart';
import 'book_detail_screen.dart';
import 'follow_list_screen.dart';

/// Profil publik pengguna lain (atau profil kita sendiri dilihat orang lain).
/// Membuat ViewModel-nya sendiri, jadi aman ditumpuk: profil -> followers -> profil.
class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserProfileViewModel>(
      create: (_) => UserProfileViewModel(
        userId: userId,
        profiles: ProfileRepositoryImpl(),
        follows: FollowRepositoryImpl(),
        quotes: QuoteRepositoryImpl(),
      )..load(),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProfileViewModel>();
    final user = vm.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          user != null ? '@${user.username}' : 'Profile',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, UserProfileViewModel vm) {
    if (vm.isLoading && vm.user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final user = vm.user;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.errorMessage ?? 'This profile could not be found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: vm.load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final fullName = (user.fullName ?? '').trim();
    final bio = (user.bio ?? '').trim();
    final stats = vm.stats;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: UserAvatar(
                username: user.username,
                avatarUrl: user.avatarUrl,
                radius: 52,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '@${user.username}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (fullName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                fullName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(child: _followButton(context, vm)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Followers',
                  value: stats.followers,
                  onTap: () => _openList(context, user.id, FollowListMode.followers),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Following',
                  value: stats.following,
                  onTap: () => _openList(context, user.id, FollowListMode.following),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Books Read', value: stats.booksRead)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Rated', value: stats.booksRated)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Quotes', value: stats.quotesSaved)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Clubs', value: stats.clubsJoined)),
            ],
          ),
          if (user.favoriteGenres.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('Favorite genres'),
            _chips(user.favoriteGenres),
          ],
          if (user.favoriteAuthors.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Favorite authors'),
            _chips(user.favoriteAuthors),
          ],
          const SizedBox(height: 24),
          _sectionTitle(
            vm.quotes.isEmpty ? 'Quotes' : 'Quotes (${vm.quotes.length})',
          ),
          if (vm.quotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No quotes saved yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...vm.quotes.take(20).map(
                  (quote) => QuoteCard(
                    quote: quote,
                    onTap: () => _openBook(context, quote),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _followButton(BuildContext context, UserProfileViewModel vm) {
    if (vm.isMe) {
      return const Text(
        'This is how other readers see your profile.',
        style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
      );
    }

    final onPressed = vm.isTogglingFollow ? null : () => _toggleFollow(context, vm);

    return SizedBox(
      width: 190,
      height: 44,
      child: vm.isFollowing
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.check, size: 18, color: AppColors.primary),
              label: const Text(
                'Following',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
    );
  }

  Future<void> _toggleFollow(BuildContext context, UserProfileViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.toggleFollow();
    if (ok) return;
    final message = vm.errorMessage;
    if (message == null) return;
    vm.clearError();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }

  void _openList(BuildContext context, String userId, FollowListMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(userId: userId, mode: mode),
      ),
    );
  }

  void _openBook(BuildContext context, QuoteEntity quote) {
    final bookId = quote.bookExternalId;
    if (bookId == null || bookId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chips(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _StatTile({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
