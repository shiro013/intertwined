import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../view_models/home_view_model.dart';
import '../widgets/book_card.dart';
import '../widgets/book_skeleton.dart';
import '../screens/book_detail_screen.dart';
import '../screens/discussion_detail_screen.dart';
import '../widgets/feed_activity_card.dart';
import '../../domain/entities/feed_activity_entity.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller disimpan di State (bukan dibuat ulang di build) supaya teks
  // tidak hilang saat halaman di-rebuild.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadBooks();
    });
  }

  void _openActivity(FeedActivityEntity activity) {
    final discussion = activity.discussion;
    if (discussion != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiscussionDetailScreen(discussion: discussion)),
      );
      return;
    }
    final bookId = activity.bookExternalId;
    if (bookId != null && bookId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
      );
    }
  }

  Future<void> _repost(HomeViewModel viewModel, FeedActivityEntity activity) async {
    final result = await viewModel.repostActivity(activity);
    if (!mounted) return;
    final message = switch (result) {
      FeedActionResult.done => 'Reposted to your feed',
      FeedActionResult.alreadyDone => 'You already reposted this',
      FeedActionResult.failed => 'Could not repost. Please try again.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result == FeedActionResult.failed ? AppColors.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final categories = [
      'All',
      'Fiction',
      'Non-Fiction',
      'Fantasy',
      'Mystery',
      'Biography',
      'Textbook',
      'Philosophy',
    ];

    return Scaffold(
      body: viewModel.isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.65,
              ),
              itemCount: 6,
              itemBuilder: (context, index) =>
                  const BookSkeleton(width: 160, height: 250),
            )
          : AnimationConfiguration.staggeredList(
              position: 0,
              delay: const Duration(milliseconds: 300),
              child: AnimationLimiter(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: viewModel.refreshHome,
                  child: CustomScrollView(
                  slivers: [
                    // --- EDITORIAL HEADER ---
                    SliverAppBar(
                      expandedHeight: 180.0,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor: AppColors.background,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                        title: Text(
                          'Intertwined',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(
                          left: 24,
                          bottom: 24,
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.background,
                                AppColors.surface.withValues(alpha: 0.3),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- SEARCH & FILTER (BENTO BLOCK 1) ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: viewModel.searchBooks,
                              onSubmitted: viewModel.submitSearch,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by title, author or ISBN',
                                hintStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon: viewModel.isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.search_rounded,
                                        color: AppColors.primary,
                                      ),
                                suffixIcon: viewModel.searchQuery.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          viewModel.clearSearch();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final isSelected =
                                      viewModel.selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          viewModel.filterByCategory(category);
                                        }
                                      },
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.surfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- TRENDING SECTION (BENTO BLOCK 2 - HERO) ---
                    if (!viewModel.isSearchActive)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                            child: Text(
                              'Trending Among Lovers',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 340,
                            child: viewModel.trendingBooks.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No trending books yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: viewModel.trendingBooks.length,
                                    itemBuilder: (context, index) {
                                      final book =
                                          viewModel.trendingBooks[index];
                                      return SlideAnimation(
                                        horizontalOffset: -100.0,
                                        child: BookCard(
                                          book: book,
                                          onTap: () => _navigateToDetail(
                                            context,
                                            book.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // --- COMMUNITY FEED (BENTO BLOCK 3 - VERTICAL) ---
                    if (!viewModel.isSearchActive)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Text(
                              'Community Activity',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ),
                          viewModel.feedActivities.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'Nothing here yet. Follow readers, join a club, or share a quote to get the feed going!',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    children: [
                                      for (final activity in viewModel.feedActivities)
                                        FadeInAnimation(
                                          child: FeedActivityCard(
                                            activity: activity,
                                            onTap: () => _openActivity(activity),
                                            onRepost: activity.canBeReposted &&
                                                    activity.userId != viewModel.currentUserId
                                                ? () => _repost(viewModel, activity)
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // --- FILTERED BOOKS GRID (BENTO BLOCK 4 - STAGGERED) ---
                    if (viewModel.isSearchActive)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Results for "${viewModel.searchQuery.trim()}"',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (viewModel.isSearching) ...[
                                const SizedBox(height: 12),
                                const LinearProgressIndicator(
                                  minHeight: 2,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.surfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      sliver: viewModel.filteredBooks.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 64,
                                      color: AppColors.surfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      viewModel.errorMessage ??
                                          (viewModel.isSearchActive
                                              ? (viewModel.isSearching
                                                  ? 'Searching...'
                                                  : 'No books found for "${viewModel.searchQuery.trim()}"')
                                              : 'No books found in this category'),
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 20,
                                    childAspectRatio: 0.65,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final book = viewModel.filteredBooks[index];
                                return FadeInAnimation(
                                  child: BookCard(
                                    book: book,
                                    isCompact: true,
                                    onTap: () =>
                                        _navigateToDetail(context, book.id),
                                  ),
                                );
                              }, childCount: viewModel.filteredBooks.length),
                            ),
                    ),
                                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _navigateToDetail(BuildContext context, String bookId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(bookId: bookId)),
    );
  }
}
