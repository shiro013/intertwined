import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/quote_entity.dart';
import '../view_models/home_view_model.dart';
import '../view_models/library_view_model.dart';
import '../view_models/quote_view_model.dart';
import '../widgets/quote_card.dart';
import 'book_detail_screen.dart';

/// Kutipan: tab "My Quotes" (koleksi pribadi, FR-13) dan "Discover" (cari kutipan
/// semua pembaca berdasarkan kata kunci, nama buku, atau tag, FR-12).
class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // My Quotes
  final _mineController = TextEditingController();
  String _mineQuery = '';
  String? _activeTag;

  // Discover
  final _discoverController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteViewModel>().loadUserQuotes();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _mineController.dispose();
    _discoverController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : null),
      );
  }

  void _openBook(QuoteEntity quote) {
    final id = quote.bookExternalId;
    if (id == null || id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)),
    );
  }

  Future<void> _confirmDelete(QuoteEntity quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete quote?', style: TextStyle(color: AppColors.primary)),
        content: const Text(
          'This quote will be removed from your collection.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final vm = context.read<QuoteViewModel>();
    final library = context.read<LibraryViewModel>();
    final ok = await vm.removeQuote(quote.id);
    if (!mounted) return;
    if (ok) {
      library.loadLibrary(silent: true); // angka "Quotes Saved" di Profil
      _snack('Quote deleted');
    } else {
      _snack(vm.errorMessage ?? 'Could not delete the quote.', error: true);
    }
  }

  void _showFeedResult(FeedActionResult result, {required String doneMessage, required String repeatMessage}) {
    _snack(
      switch (result) {
        FeedActionResult.done => doneMessage,
        FeedActionResult.alreadyDone => repeatMessage,
        FeedActionResult.failed => 'Something went wrong. Please try again.',
      },
      error: result == FeedActionResult.failed,
    );
  }

  Future<void> _shareToFeed(QuoteEntity quote) async {
    final result = await context.read<HomeViewModel>().shareQuote(quote);
    if (!mounted) return;
    _showFeedResult(
      result,
      doneMessage: 'Shared to the community feed',
      repeatMessage: 'You already shared this quote',
    );
  }

  Future<void> _repostQuote(QuoteEntity quote) async {
    final result = await context.read<HomeViewModel>().repostQuote(quote);
    if (!mounted) return;
    _showFeedResult(
      result,
      doneMessage: 'Reposted to your feed',
      repeatMessage: 'You already reposted this quote',
    );
  }

  void _searchFor(String text) {
    _discoverController.text = text;
    _discoverController.selection = TextSelection.collapsed(offset: text.length);
    _debounce?.cancel();
    context.read<QuoteViewModel>().search(text);
  }

  void _searchByTag(String tag) {
    _tabController.animateTo(1);
    _searchFor(tag);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuoteViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quotes',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: vm.userQuotes.isEmpty ? 'My Quotes' : 'My Quotes (${vm.userQuotes.length})'),
            const Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMine(vm), _buildDiscover(vm)],
      ),
    );
  }

  // ------------------------------------------------------------- My Quotes

  Widget _buildMine(QuoteViewModel vm) {
    if (vm.isLoading || !vm.hasLoaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (vm.errorMessage != null && vm.userQuotes.isEmpty) {
      return _message(
        icon: Icons.cloud_off,
        text: vm.errorMessage!,
        action: ElevatedButton(
          onPressed: () => vm.loadUserQuotes(),
          child: const Text('Try again'),
        ),
      );
    }

    final filtered = vm.filterUserQuotes(query: _mineQuery, tag: _activeTag);
    final tags = vm.userTags;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.loadUserQuotes(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          TextField(
            controller: _mineController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (value) => setState(() => _mineQuery = value),
            decoration: InputDecoration(
              hintText: 'Search your quotes, books or tags',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _mineQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () {
                        _mineController.clear();
                        setState(() => _mineQuery = '');
                      },
                    ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final selected = _activeTag == tag;
                  return FilterChip(
                    label: Text('#$tag'),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                    ),
                    onSelected: (_) => setState(() => _activeTag = selected ? null : tag),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (vm.userQuotes.isEmpty)
            _inlineMessage(
              Icons.format_quote,
              'You have not saved any quotes yet.\nOpen a book and tap "Save Quote".',
            )
          else if (filtered.isEmpty)
            _inlineMessage(Icons.search_off, 'No quotes match your search.')
          else
            for (final quote in filtered)
              QuoteCard(
                quote: quote,
                activeTag: _activeTag,
                onTap: () => _openBook(quote),
                onShare: () => _shareToFeed(quote),
                onDelete: () => _confirmDelete(quote),
                onTagTap: (tag) => setState(() {
                  final t = tag.trim().toLowerCase();
                  _activeTag = _activeTag == t ? null : t;
                }),
              ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Discover

  Widget _buildDiscover(QuoteViewModel vm) {
    final myId = vm.currentUserId;

    Widget body;
    if (vm.isSearching && vm.results.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    } else if (vm.searchError != null) {
      body = _message(
        icon: Icons.cloud_off,
        text: vm.searchError!,
        action: ElevatedButton(
          onPressed: () => vm.search(vm.lastQuery),
          child: const Text('Try again'),
        ),
      );
    } else if (!vm.hasSearched) {
      body = _inlineMessage(
        Icons.travel_explore,
        'Search quotes from every reader by a word or phrase, a book title, or a tag.',
      );
    } else if (vm.results.isEmpty) {
      body = _inlineMessage(Icons.search_off, 'No quotes found for "${vm.lastQuery}".');
    } else {
      body = Column(
        children: [
          for (final quote in vm.results)
            QuoteCard(
              quote: quote,
              showAuthor: true,
              onTap: () => _openBook(quote),
              onTagTap: _searchByTag,
              onRepost: quote.userId == myId ? null : () => _repostQuote(quote),
              onShare: quote.userId == myId ? () => _shareToFeed(quote) : null,
              onDelete: quote.userId == myId ? () => _confirmDelete(quote) : null,
            ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        TextField(
          controller: _discoverController,
          style: const TextStyle(color: AppColors.textPrimary),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              if (mounted) context.read<QuoteViewModel>().search(value);
            });
            setState(() {}); // memperbarui tombol hapus
          },
          onSubmitted: (value) {
            _debounce?.cancel();
            context.read<QuoteViewModel>().search(value);
          },
          decoration: InputDecoration(
            hintText: 'Search by keyword, book or tag',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: vm.isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _discoverController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _discoverController.clear();
                      _debounce?.cancel();
                      vm.search('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        body,
      ],
    );
  }

  // --------------------------------------------------------------- helpers

  Widget _inlineMessage(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _message({required IconData icon, required String text, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
