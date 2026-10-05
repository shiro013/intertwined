import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/community_entities.dart';
import '../view_models/community_view_model.dart';
import '../widgets/like_button.dart';
import '../widgets/user_avatar.dart';

/// Satu diskusi + komentar berjenjang (balasan bisa membalas balasan).
class DiscussionDetailScreen extends StatefulWidget {
  final CommunityDiscussion discussion;

  const DiscussionDetailScreen({super.key, required this.discussion});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  static const int _maxIndentLevel = 3;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  CommunityComment? _replyTo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().loadComments(widget.discussion.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startReply(CommunityComment comment) {
    setState(() => _replyTo = comment);
    _focusNode.requestFocus();
  }

  Future<void> _send() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    final vm = context.read<CommunityViewModel>();
    setState(() => _sending = true);

    final ok = await vm.submitComment(
      widget.discussion.id,
      text,
      parentCommentId: _replyTo?.id,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (ok) _replyTo = null;
    });

    if (ok) {
      _commentController.clear();
    } else {
      // teks dibiarkan supaya user tidak perlu mengetik ulang
      _snack(vm.errorMessage ?? 'Failed to post comment');
      vm.clearError();
    }
  }

  /// Ratakan daftar komentar menjadi urutan tampil (induk lalu anak-anaknya).
  List<_ThreadItem> _buildThread(List<CommunityComment> all) {
    final ids = all.map((c) => c.id).toSet();
    final children = <String, List<CommunityComment>>{};
    final roots = <CommunityComment>[];

    for (final c in all) {
      final parent = c.parentCommentId;
      // induk tidak ditemukan (mis. terhapus) -> perlakukan sebagai komentar tingkat atas
      if (parent == null || !ids.contains(parent)) {
        roots.add(c);
      } else {
        children.putIfAbsent(parent, () => []).add(c);
      }
    }

    final out = <_ThreadItem>[];
    void walk(CommunityComment c, int depth) {
      out.add(_ThreadItem(c, depth));
      for (final child in children[c.id] ?? const <CommunityComment>[]) {
        walk(child, depth < _maxIndentLevel ? depth + 1 : depth);
      }
    }

    for (final root in roots) {
      walk(root, 0);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunityViewModel>();
    // ambil versi terbaru (jumlah like/balasan) dari ViewModel
    final discussion = vm.discussionById(widget.discussion.id) ?? widget.discussion;
    final comments =
        vm.activeDiscussionId == discussion.id ? vm.comments : <CommunityComment>[];
    final thread = _buildThread(comments);
    final loading = vm.isCommentsLoading && comments.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildPost(vm, discussion),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    comments.isEmpty ? 'Replies' : 'Replies (${comments.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (thread.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No replies yet. Be the first!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final item in thread)
                    CommentTile(
                      comment: item.comment,
                      depth: item.depth,
                      onReply: () => _startReply(item.comment),
                    ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPost(CommunityViewModel vm, CommunityDiscussion discussion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(username: discussion.username, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.username ?? 'Unknown User',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (discussion.groupName != null && discussion.groupName!.isNotEmpty)
                      Text(
                        'in ${discussion.groupName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                timeAgo(discussion.createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            discussion.content,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              LikeButton(
                liked: discussion.likedByMe,
                count: discussion.likeCount,
                onTap: () => vm.toggleDiscussionLike(discussion.id),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${discussion.replyCount}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final replyTo = _replyTo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTo != null)
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to ${replyTo.username ?? 'Unknown User'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancel reply',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: AppColors.textPrimary),
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: replyTo == null ? 'Write a comment...' : 'Write a reply...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: AppColors.onPrimary, size: 20),
                            onPressed: _send,
                          ),
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

class _ThreadItem {
  final CommunityComment comment;
  final int depth;

  const _ThreadItem(this.comment, this.depth);
}

class CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final int depth;
  final VoidCallback? onReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.depth = 0,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20 + depth * 18.0, 6, 20, 6),
      child: Container(
        // garis tipis di kiri menandai balasan (tanpa borderRadius -> aman untuk Border non-uniform)
        decoration: depth > 0
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              )
            : null,
        padding: EdgeInsets.only(left: depth > 0 ? 10 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(username: comment.username, radius: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.username ?? 'Unknown User',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(comment.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.35),
                  ),
                  if (onReply != null)
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
