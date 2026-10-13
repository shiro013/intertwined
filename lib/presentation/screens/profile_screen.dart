import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/library_view_model.dart';
import '../../core/theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'quotes_screen.dart';
import 'privacy_security_screen.dart';

import '../widgets/follow_counts_row.dart';
import 'find_readers_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserProfile();
      context.read<LibraryViewModel>().loadLibrary();
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Log out?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will need to sign in again to use Intertwined.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Setelah sesi berakhir, root aplikasi me-reset semua data pengguna dan
    // AuthGate menampilkan layar login; tidak perlu navigasi manual.
    final vm = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.signOut();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Could not log out.')),
      );
    }
  }

  void _openEditProfile() {
    if (context.read<ProfileViewModel>().user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final libraryVm = context.watch<LibraryViewModel>();
    final user = profileVm.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: _openEditProfile,
          ),
        ],
      ),
      body: profileVm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: UserAvatar(
                            username: user?.username,
                            avatarUrl: user?.avatarUrl,
                            radius: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.username ?? 'User',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if ((user?.fullName ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user!.fullName!.trim(),
                            style: const TextStyle(color: AppColors.primary, fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            (user?.bio ?? '').trim().isEmpty ? 'No bio available' : user!.bio!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                                    _buildStatsSection(libraryVm),
                  if (user != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FollowCountsRow(userId: user.id),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Favorite Genres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTagWrap(
                          user?.favoriteGenres ?? const [],
                          'No favorite genres yet. Add some with the edit button.',
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Favorite Authors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTagWrap(
                          user?.favoriteAuthors ?? const [],
                          'No favorite authors yet. Add some with the edit button.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          icon: Icons.person_search,
                          title: 'Find Readers',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FindReadersScreen()),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.format_quote,
                          title: 'My Quotes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuotesScreen()),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                        ),
                        _buildProfileOption(
                          icon: Icons.lock_outline,
                          title: 'Privacy & Security',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.withValues(alpha: 0.2),
                              foregroundColor: AppColors.error,
                            ),
                            onPressed: _confirmLogout,
                            child: const Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTagWrap(List<String> tags, String emptyText) {
    if (tags.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Chip(
          label: Text(
            tag,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection(LibraryViewModel libraryVm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Books Rated', libraryVm.totalBooksRated.toString())),
          Expanded(child: _buildStatItem('Books Read', libraryVm.totalBooksRead.toString())),
          Expanded(child: _buildStatItem('Quotes Saved', libraryVm.totalQuotesSaved.toString())),
          Expanded(child: _buildStatItem('Clubs Joined', libraryVm.totalGroupsJoined.toString())),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
