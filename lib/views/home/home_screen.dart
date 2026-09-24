import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/book.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeViewModel>().loadUserProfile();
        context.read<HomeViewModel>().loadRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Intertwined',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authVM.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting
              Text(
                'Hello, ${homeVM.userName}! 👋',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                'What are we discussing today?',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // My Library Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Library',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/library'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recommended Books (Horizontal Scroll)
              SizedBox(
                height: 240,
                child: homeVM.isLoadingRecommended
                    ? const Center(child: CircularProgressIndicator())
                    : homeVM.recommendedBooks.isEmpty
                        ? const Center(child: Text('No recommendations available'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: homeVM.recommendedBooks.length,
                            itemBuilder: (context, index) {
                              final book = homeVM.recommendedBooks[index];
                              return _buildRecommendationCard(context, book);
                            },
                          ),
              ),
              const SizedBox(height: 32),

              // Modern Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books, authors, ISBN...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      homeVM.searchBooks('');
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                onChanged: (value) => homeVM.searchBooks(value),
              ),
              const SizedBox(height: 32),

              // Search Results
              const Text(
                'Community Discoveries',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              homeVM.isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : homeVM.searchResults.isEmpty
                      ? _buildEmptySearch()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: homeVM.searchResults.length,
                          itemBuilder: (context, index) {
                            final book = homeVM.searchResults[index];
                            return _buildSearchResultCard(context, book, homeVM);
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Book book) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/book-detail', arguments: book.id),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          width: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Book book, HomeViewModel homeVM) {
    final bool isExternal = book.id.length < 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl != null
              ? Image.network(book.coverUrl!, width: 50, height: 70, fit: BoxFit.cover)
              : Container(width: 50, height: 70, color: Colors.grey[300], child: const Icon(Icons.book)),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(book.author),
        trailing: isExternal
            ? IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 30),
                onPressed: () async {
                  try {
                    await homeVM.addBookToLibrary(book);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to your collection!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add book')),
                      );
                    }
                  }
                },
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        onTap: () => Navigator.pushNamed(context, '/book-detail', arguments: book.id),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 160,
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 50, color: Colors.white),
    );
  }

  Widget _buildEmptySearch() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No books found. Try another keyword!',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
