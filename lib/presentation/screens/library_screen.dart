import 'package:flutter/material.dart';

import 'book_detail_screen.dart';

import 'package:intertwined/domain/entities/book_entity.dart';
import 'package:provider/provider.dart';

import '../view_models/library_view_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryViewModel>().loadLibrary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'My Collection',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                child: Container(
                  color: AppColors.background,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Want'),
                      Tab(text: 'Reading'),
                      Tab(text: 'Finished'),
                    ],
                    onTap: (index) {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBookGrid(viewModel.myBooks),
            _buildBookGrid(viewModel.wantToReadBooks),
            _buildBookGrid(viewModel.readingBooks),
            _buildBookGrid(viewModel.finishedBooks),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<BookEntity> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              color: AppColors.primary.withValues(alpha: 0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your shelf is waiting for a new story',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          isCompact: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(item: book),
            ),
          ),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
