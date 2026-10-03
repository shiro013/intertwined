import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/community_entities.dart';
import '../view_models/community_view_model.dart';
import '../widgets/discussion_card.dart';
import 'discussion_detail_screen.dart';

/// Daftar diskusi satu klub. Dibuka dengan salah satu dari:
///  - [bookUuid] + [bookTitle]: klub untuk buku itu (dibuat otomatis kalau belum ada)
///  - [group]: klub yang sudah ada (mis. dari kartu "Featured Book Clubs")
class DiscussionThreadScreen extends StatefulWidget {
  final String? bookUuid;
  final String? bookTitle;
  final CommunityGroup? group;

  const DiscussionThreadScreen({
    super.key,
    this.bookUuid,
    this.bookTitle,
    this.group,
  }) : assert(bookUuid != null || group != null, 'Provide a bookUuid or a group');

  @override
  State<DiscussionThreadScreen> createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends State<DiscussionThreadScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    _started = true;
    final vm = context.read<CommunityViewModel>();
    final group = widget.group;
    if (group != null) return vm.openGroup(group);
    return vm.openGroupForBook(
      bookUuid: widget.bookUuid!,
      bookTitle: widget.bookTitle ?? 'Book',
    );
  }

  /// ViewModel dipakai bersama; pastikan grup aktif memang grup yang dibuka layar ini
  /// (bukan sisa dari kunjungan sebelumnya).
  bool _isMine(CommunityGroup g) {
    final expected = widget.group;
    if (expected != null) return g.id == expected.id;
    return g.relatedBookId == widget.bookUuid;
  }

  void _flushError(CommunityViewModel vm) {
    final msg = vm.errorMessage;
    if (msg == null) return;
    vm.clearError();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  void _showStartDiscussionDialog(CommunityGroup group) {
    final vm = context.read<CommunityViewModel>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Start a Discussion', style: TextStyle(color: AppColors.primary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'What is on your mind?',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          // Rebuild lewat Consumer supaya tombol nonaktif selama posting
          Consumer<CommunityViewModel>(
            builder: (_, model, __) => ElevatedButton(
              onPressed: model.isPosting
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      final ok = await vm.createDiscussion(group.id, text);
                      if (!dialogContext.mounted) return;
                      // Gagal -> dialog tetap terbuka (teks tidak hilang);
                      // pesan error muncul lewat snackbar.
                      if (ok) Navigator.pop(dialogContext);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                model.isPosting ? 'Posting…' : 'Post',
                style: const TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunityViewModel>();
    final active = vm.activeGroup;
    final group = (active != null && _isMine(active)) ? active : null;
    _flushError(vm);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group?.name ?? widget.group?.name ?? widget.bookTitle ?? 'Book Discussion',
          style: const TextStyle(color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _buildBody(vm, group),
      floatingActionButton: group == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showStartDiscussionDialog(group),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.edit, color: AppColors.onPrimary),
              label: const Text(
                'New post',
                style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _buildBody(CommunityViewModel vm, CommunityGroup? group) {
    if (group == null) {
      if (!_started || vm.isGroupLoading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              Text(
                vm.groupError ?? 'Could not open this club.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Try again', style: TextStyle(color: AppColors.onPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    final discussions = vm.groupDiscussions;
    final joined = vm.isActiveGroupJoined;
    final busy = vm.isGroupBusy(group.id);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: vm.refreshActiveGroup,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ---- header klub
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    group.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const Spacer(),
                    busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => vm.toggleMembership(group.id),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: joined ? Colors.transparent : AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            child: Text(
                              joined ? 'Joined' : 'Join club',
                              style: TextStyle(
                                color: joined ? AppColors.primary : AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),

          // ---- diskusi
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              discussions.isEmpty ? 'Discussions' : 'Discussions (${discussions.length})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (vm.isGroupLoading && discussions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (discussions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No discussions yet. Start the conversation!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final d in discussions)
              DiscussionCard(
                discussion: d,
                onLike: () => vm.toggleDiscussionLike(d.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiscussionDetailScreen(discussion: d),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
