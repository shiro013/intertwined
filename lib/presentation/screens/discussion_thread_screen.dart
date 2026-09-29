import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/community_view_model.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/community_entities.dart';

class DiscussionThreadScreen extends StatefulWidget {
  final String? bookId;

  const DiscussionThreadScreen({super.key, this.bookId});

  @override
  State<DiscussionThreadScreen> createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends State<DiscussionThreadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bookId != null) {
        context.read<CommunityViewModel>().fetchBookDiscussions(widget.bookId!);
      } else {
        context.read<CommunityViewModel>().fetchCommunityData();
      }
    });
  }

  void _showStartDiscussionDialog() {
    final controller = TextEditingController();
    final viewModel = context.read<CommunityViewModel>();

    // We need a groupId to start a discussion.
    // If we came from a book, we find that group.
    String? groupId;
    if (viewModel.groups.isNotEmpty) {
      if (widget.bookId != null) {
        groupId = viewModel.groups
            .firstWhere(
              (g) => g.relatedBookId == widget.bookId,
              orElse: () => CommunityGroup(
                id: '',
                name: '',
                description: '',
                coverUrl: '',
                memberCount: 0,
                relatedBookId: '',
              ),
            )
            .id;
      } else {
        groupId = viewModel.groups.first.id;
      }
    }

    if (groupId == null || groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please join a group first to start a discussion'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Start a Discussion',
          style: TextStyle(color: AppColors.primary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'What is on your mind about this book?',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await viewModel.createDiscussion(groupId!, controller.text);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityViewModel>();
    final discussions = widget.bookId != null
        ? viewModel.bookDiscussions
        : viewModel.recentDiscussions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bookId != null ? 'Book Discussion' : 'Community Feed',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: viewModel.isLoading && discussions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : discussions.isEmpty
          ? const Center(
              child: Text(
                'No discussions yet. Start the conversation!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: discussions.length,
              itemBuilder: (context, index) {
                final discussion = discussions[index];
                return DiscussionCard(
                  discussion: discussion,
                  onTap: () async {
                    await viewModel.loadComments(discussion.id);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DiscussionDetailScreen(discussion: discussion),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStartDiscussionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class DiscussionCard extends StatelessWidget {
  final CommunityDiscussion discussion;
  final VoidCallback onTap;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          discussion.username ?? 'Unknown User',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              discussion.content,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${discussion.replyCount} replies',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${discussion.createdAt.day}/${discussion.createdAt.month}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class DiscussionDetailScreen extends StatefulWidget {
  final CommunityDiscussion discussion;

  const DiscussionDetailScreen({super.key, required this.discussion});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityViewModel>();
    final comments = viewModel.comments;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discussion',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Main Post
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.discussion.username ?? 'Unknown User',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.discussion.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.discussion.createdAt.day}/${widget.discussion.createdAt.month}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text('No comments yet. Be the first!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return CommentTile(comment: comment);
                    },
                  ),
          ),
          // Input Area
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty) {
                        await viewModel.submitComment(
                          widget.discussion.id,
                          _commentController.text,
                        );
                        _commentController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final CommunityComment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(Icons.person, size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username ?? 'Unknown User',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${comment.createdAt.day}/${comment.createdAt.month}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
