import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../view_models/book_detail_view_model.dart';
import '../widgets/book_community_card.dart';
import '../widgets/book_quotes_section.dart';
import '../widgets/book_reviews_section.dart';
import '../widgets/safe_network_image.dart';
import 'discussion_thread_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  String? _syncedReview; // review terakhir yang dimasukkan ke controller

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookDetailViewModel>().loadBookDetails(widget.bookId);
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Error dari ViewModel ditampilkan sekali lalu dibersihkan.
  void _showError(BookDetailViewModel vm) {
    final msg = vm.errorMessage;
    if (msg == null) return;
    vm.clearError();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _snack(msg);
    });
  }

  // ---------------------------------------------------------------- actions

  Future<void> _openCommunity(BookDetailViewModel vm) async {
    final book = vm.book;
    final uuid = vm.bookUuid;
    if (book == null || uuid == null) {
      _snack('This book is still syncing. Please try again in a moment.');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionThreadScreen(bookUuid: uuid, bookTitle: book.title),
      ),
    );
    if (!mounted) return;
    vm.refreshCommunity(); // diskusi/anggota mungkin berubah
  }

  Future<void> _changeStatus(
    BookDetailViewModel vm,
    BookReadingStatus status,
    bool wasSelected,
  ) async {
    // klik chip yang sedang aktif = keluarkan dari library
    final ok = await vm.setReadingStatus(wasSelected ? null : status);
    if (!mounted || !ok) return;
    _snack(wasSelected
        ? 'Removed from your library'
        : 'Moved to "${_statusLabel(status)}" in your library');
  }

  Future<void> _toggleBookmark(BookDetailViewModel vm) async {
    final willBookmark = !(vm.interaction?.isBookmarked ?? false);
    final ok = await vm.toggleBookmark();
    if (!mounted || !ok) return;
    _snack(willBookmark ? 'Saved to your bookmarks' : 'Bookmark removed');
  }

  Future<void> _saveReview(BookDetailViewModel vm) async {
    final ok = await vm.saveReview(_reviewController.text);
    if (!mounted || !ok) return;
    _snack('Review saved!');
  }

  void _showAddQuoteDialog() {
    final vm = context.read<BookDetailViewModel>();
    final quoteController = TextEditingController();
    final pageController = TextEditingController();
    final tagController = TextEditingController();
    var saving = false;

    InputDecoration field(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Save Favorite Quote', style: TextStyle(color: AppColors.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quoteController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: field('Enter the quote text...'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: field('Page number (optional)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: field('Tags (comma separated, e.g. inspiring, sad)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final text = quoteController.text.trim();
                      if (text.isEmpty) return;
                      final tags = tagController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      setDialogState(() => saving = true);
                      final ok = await vm.addQuote(
                        text,
                        int.tryParse(pageController.text.trim()) ?? 0,
                        tags,
                      );
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(dialogContext);
                        _snack('Quote saved to your collection!');
                      } else {
                        setDialogState(() => saving = false); // error tampil via snackbar
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                saving ? 'Saving…' : 'Save Quote',
                style: const TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  String _statusLabel(BookReadingStatus s) {
    switch (s) {
      case BookReadingStatus.wantToRead:
        return 'Want to read';
      case BookReadingStatus.reading:
        return 'Reading';
      case BookReadingStatus.finished:
        return 'Finished';
    }
  }

  String _ratingText(BookDetailViewModel vm, BookEntity book) {
    final count = vm.communityReviewCount;
    if (count > 0) {
      return '${vm.communityAverage.toStringAsFixed(1)} ($count ${count == 1 ? 'review' : 'reviews'})';
    }
    if (book.averageRating > 0) {
      return '${book.averageRating.toStringAsFixed(1)} · Google Books';
    }
    return vm.isSocialLoading ? 'Loading ratings…' : 'No ratings yet';
  }

  Widget _buildStatusCard(BookDetailViewModel vm) {
    final interaction = vm.interaction;
    final current = interaction?.status;
    final bookmarked = interaction?.isBookmarked == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('MY SHELF', style: Theme.of(context).textTheme.bodySmall),
              ),
              IconButton(
                tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark this book',
                onPressed: vm.isSaving ? null : () => _toggleBookmark(vm),
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final status in BookReadingStatus.values)
                ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: current == status,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: current == status ? AppColors.onPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: vm.isSaving
                      ? null
                      : (_) => _changeStatus(vm, status, current == status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current == null
                ? 'Pick a shelf to add this book to your library.'
                : 'Tap the selected shelf again to remove it from your library.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (vm.isSaving) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewBox(BookDetailViewModel vm) {
    final interaction = vm.interaction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Review', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: vm.isSaving ? null : () => vm.updateRating(index + 1),
                icon: Icon(
                  index < (interaction?.rating ?? 0) ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  size: 30,
                ),
              );
            }),
          ),
          if ((interaction?.rating ?? 0) == 0)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Tap a star to rate first, then write your thoughts.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this book...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: vm.isSaving ? null : () => _saveReview(vm),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save Review', style: TextStyle(color: AppColors.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookDetailViewModel>();
    final book = vm.book;
    final interaction = vm.interaction;
    _showError(vm);

    if (interaction != null && _syncedReview != interaction.review) {
      _syncedReview = interaction.review;
      _reviewController.text = interaction.review;
    }

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SafeNetworkImage(
                    url: book.coverUrl,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.book, color: AppColors.primary, size: 80),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.8),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${book.author}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _ratingText(vm, book),
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatusCard(vm),
                  const SizedBox(height: 20),
                  BookCommunityCard(
                    group: vm.group,
                    discussions: vm.previewDiscussions,
                    isLoading: vm.isSocialLoading,
                    onOpen: () => _openCommunity(vm),
                  ),
                  const SizedBox(height: 30),
                  Text('Synopsis', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    book.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vm.quotes.isEmpty ? 'Quotes' : 'Quotes (${vm.quotes.length})',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddQuoteDialog,
                        icon: const Icon(Icons.format_quote, color: AppColors.primary),
                        label: const Text('Save Quote', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  BookQuotesSection(
                    quotes: vm.quotes,
                    currentUserId: vm.currentUserId,
                    isLoading: vm.isSocialLoading,
                    onDelete: vm.removeQuote,
                  ),
                  const SizedBox(height: 30),
                  _buildReviewBox(vm),
                  const SizedBox(height: 30),
                  BookReviewsSection(
                    reviews: vm.reviews,
                    currentUserId: vm.currentUserId,
                    isLoading: vm.isSocialLoading,
                    onToggleLike: vm.toggleReviewLike,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
