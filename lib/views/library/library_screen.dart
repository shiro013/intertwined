import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../../models/book.dart';
import '../../models/reading_status.dart';
import '../../models/library_item.dart'; // Note: We'll move LibraryItem to a separate model file for better structure

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryViewModel>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LibraryViewModel>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Want to Read'),
              Tab(text: 'Reading'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookList(vm.wantToReadBooks),
                  _buildBookList(vm.currentlyReadingBooks),
                  _buildBookList(vm.finishedBooks),
                ],
              ),
      ),
    );
  }

  Widget _buildBookList(List<LibraryItem> books) {
    if (books.isEmpty) {
      return const Center(child: Text('No books in this category yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final item = books[index];
        final book = item.book;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: book.coverUrl != null
                ? Image.network(book.coverUrl!, width: 50, fit: BoxFit.cover)
                : const Icon(Icons.book),
            title: Text(book.title),
            subtitle: Text(book.author),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/book-detail',
                arguments: book.id,
              );
            },
          ),
        );
      },
    );
  }
}
