import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/entities/user_book_interaction_entity.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryViewModel>().loadLibrary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _label(String name, int count) => count > 0 ? '$name ($count)' : name;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Collection',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: _label('All', vm.allItems.length)),
            Tab(text: _label('Want', vm.wantToReadItems.length)),
            Tab(text: _label('Reading', vm.readingItems.length)),
            Tab(text: _label('Finished', vm.finishedItems.length)),
            Tab(text: _label('Saved', vm.bookmarkedItems.length)),
          ],
        ),
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(LibraryViewModel vm) {
    if (vm.isLoading || !vm.hasLoaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (vm.errorMessage != null && vm.items.isEmpty) {
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
                onPressed: () => vm.loadLibrary(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Try again', style: TextStyle(color: AppColors.onPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildGrid(vm, vm.allItems, 'Your shelf is waiting for a new story.\nOpen a book and pick a shelf to add it here.'),
        _buildGrid(vm, vm.wantToReadItems, 'No books on your "Want to read" shelf yet.'),
        _buildGrid(vm, vm.readingItems, 'You are not reading anything right now.'),
        _buildGrid(vm, vm.finishedItems, 'No finished books yet.'),
        _buildGrid(vm, vm.bookmarkedItems, 'Tap the bookmark icon on a book to save it here.'),
      ],
    );
  }

  Widget _buildGrid(LibraryViewModel vm, List<LibraryItemEntity> items, String emptyText) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.loadLibrary(silent: true),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 360,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: AppColors.primary.withValues(alpha: 0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyText,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.65,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return BookCard(
                  book: item.book,
                  isCompact: true,
                  badge: _Badges(item: item),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailScreen(bookId: item.book.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Ikon kecil di pojok kartu: status baca + bookmark.
class _Badges extends StatelessWidget {
  final LibraryItemEntity item;

  const _Badges({required this.item});

  IconData? get _statusIcon {
    switch (item.status) {
      case BookReadingStatus.wantToRead:
        return Icons.schedule;
      case BookReadingStatus.reading:
        return Icons.auto_stories;
      case BookReadingStatus.finished:
        return Icons.check_circle;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      if (_statusIcon != null) _statusIcon!,
      if (item.isBookmarked) Icons.bookmark,
    ];
    if (icons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final icon in icons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(icon, size: 14, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
