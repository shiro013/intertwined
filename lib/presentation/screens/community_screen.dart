import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/community_entities.dart';
import '../view_models/community_view_model.dart';
import '../widgets/discussion_card.dart';
import '../widgets/safe_network_image.dart';
import 'discussion_detail_screen.dart';
import 'discussion_thread_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().fetchCommunityData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _flushError(CommunityViewModel vm) {
    final msg = vm.errorMessage;
    // error load awal ditampilkan sebagai layar error, bukan snackbar
    if (msg == null || (vm.groups.isEmpty && vm.recentDiscussions.isEmpty)) return;
    vm.clearError();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  void _openGroup(CommunityGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscussionThreadScreen(group: group)),
    ).then((_) {
      if (mounted) context.read<CommunityViewModel>().fetchCommunityData(silent: true);
    });
  }

  void _openDiscussion(CommunityDiscussion discussion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionDetailScreen(discussion: discussion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunityViewModel>();
    _flushError(vm);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Hub',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(CommunityViewModel vm) {
    if (vm.isLoading || !vm.hasLoaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (vm.errorMessage != null && vm.groups.isEmpty && vm.recentDiscussions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => vm.fetchCommunityData(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Try again', style: TextStyle(color: AppColors.onPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    final joinedGroups = vm.joinedGroups;
    final discoverGroups = vm.discoverGroups;
    final discussions = vm.filteredDiscussions;
    final searching = vm.searchQuery.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.fetchCommunityData(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: vm.setSearchQuery,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search clubs or your discussions...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          vm.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ---- klub yang sudah diikuti
          _SectionTitle(
            vm.joinedCount > 0 ? 'Your Clubs (${vm.joinedCount})' : 'Your Clubs',
          ),
          if (joinedGroups.isEmpty)
            _EmptyHint(
              searching
                  ? 'None of your clubs match your search.'
                  : "You haven't joined any club yet. Join one below, or open a book and tap \"Start Discussion\".",
            )
          else
            SizedBox(
              height: 178,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: joinedGroups.length,
                itemBuilder: (context, index) => _JoinedGroupCard(
                  group: joinedGroups[index],
                  onOpen: () => _openGroup(joinedGroups[index]),
                ),
              ),
            ),

          // ---- klub lain yang bisa diikuti
          const _SectionTitle('Discover Clubs'),
          if (discoverGroups.isEmpty)
            _EmptyHint(
              searching
                  ? 'No other clubs match your search.'
                  : (vm.groups.isEmpty
                      ? 'No clubs yet. Open any book and tap "Start Discussion" to create the first one.'
                      : "You've joined every club for now!"),
            )
          else
            SizedBox(
              height: 205,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: discoverGroups.length,
                itemBuilder: (context, index) => _GroupCard(
                  group: discoverGroups[index],
                  joined: false,
                  busy: vm.isGroupBusy(discoverGroups[index].id),
                  onOpen: () => _openGroup(discoverGroups[index]),
                  onToggleJoin: () => vm.toggleMembership(discoverGroups[index].id),
                ),
              ),
            ),
          const _SectionTitle('Your Recent Discussions'),
          if (discussions.isEmpty)
            _EmptyHint(
              searching
                  ? 'No discussions match your search.'
                  : "You haven't posted any discussions yet. Open a club and start one!",
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final d in discussions)
                    DiscussionCard(
                      discussion: d,
                      showGroup: true,
                      onLike: () => vm.toggleDiscussionLike(d.id),
                      onTap: () => _openDiscussion(d),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final CommunityGroup group;
  final bool joined;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onToggleJoin;

  const _GroupCard({
    required this.group,
    required this.joined,
    required this.busy,
    required this.onOpen,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SafeNetworkImage(
                url: group.coverUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      SizedBox(
                        height: 30,
                        child: busy
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: onToggleJoin,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: Size.zero,
                                  backgroundColor: joined ? Colors.transparent : AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                                child: Text(
                                  joined ? 'Joined' : 'Join',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: joined ? AppColors.primary : AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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

/// Kartu untuk klub yang SUDAH diikuti: border emas + label "Member" supaya
/// langsung terlihat. Keluar dari klub dilakukan di halaman klub (bukan di sini),
/// agar tidak terjadi tap tidak sengaja.
class _JoinedGroupCard extends StatelessWidget {
  final CommunityGroup group;
  final VoidCallback onOpen;

  const _JoinedGroupCard({required this.group, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SafeNetworkImage(
                url: group.coverUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text(
                              'Member',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
