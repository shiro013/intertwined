import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../view_models/home_view_model.dart';
import '../widgets/book_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../widgets/state_views/state_views.dart';
import '../../domain/entities/book_entity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final categories = ['All', 'Fiction', 'Non-Fiction', 'Fantasy', 'Mystery', 'Biography', 'Textbook', 'Philosophy'];

    return Scaffold(
      body: _buildContent(viewModel, categories),
    );
  }

  Widget _buildContent(HomeViewModel viewModel, List<String> categories) {
    switch (viewModel.status) {
      case ViewStatus.loading:
        return const LoadingView();
      case ViewStatus.error:
        return ErrorView(
          message: viewModel.errorMessage ?? 'An unknown error occurred',
          onRetry: () => viewModel.loadBooks(),
        );
      case ViewStatus.success:
        if (viewModel.filteredBooks.isEmpty) {
          return const EmptyView(message: 'Belum ada data buku.');
        }
        return _buildMainUI(viewModel, categories);
    }
  }

  Widget _buildMainUI(HomeViewModel viewModel, List<String> categories) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      delay: const Duration(milliseconds: 300),
      child: AnimationLimiter(
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
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                title: Text(
                  'Intertwined',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 24, bottom: 24),
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

            // --- SEARCH & FILTER ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: viewModel.searchBooks,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search your next literary escape...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1),
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
                          final isSelected = viewModel.selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) viewModel.filterByCategory(category);
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
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

            // --- TRENDING SECTION ---
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
                        ? const Center(child: Text('No trending books yet', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: viewModel.trendingBooks.length,
                            itemBuilder: (context, index) {
                              final book = viewModel.trendingBooks[index];
                              return SlideAnimation(
                                horizontalOffset: -100.0,
                                child: BookCard(
                                  book: book,
                                  onTap: () => _navigateToDetail(context, book),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // --- FILTERED BOOKS GRID ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = viewModel.filteredBooks[index];
                    return FadeInAnimation(
                      child: BookCard(
                        book: book,
                        isCompact: true,
                        onTap: () => _navigateToDetail(context, book),
                      ),
                    );
                  },
                  childCount: viewModel.filteredBooks.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, BookEntity book) {
    Navigator.pushNamed(context, AppRoutes.detail, arguments: book);
  }
}
