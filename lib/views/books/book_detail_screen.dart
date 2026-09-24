import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/book_detail_viewmodel.dart';
import '../../viewmodels/quote_viewmodel.dart';
import '../../viewmodels/review_viewmodel.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookDetailViewModel>().loadBookDetails(widget.bookId);
      context.read<QuoteViewModel>().loadQuotes(widget.bookId);
      context.read<ReviewViewModel>().loadReviews(widget.bookId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookVM = Provider.of<BookDetailViewModel>(context);
    final quoteVM = Provider.of<QuoteViewModel>(context);
    final reviewVM = Provider.of<ReviewViewModel>(context);

    if (bookVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (bookVM.book == null) {
      return const Scaffold(body: Center(child: Text('Book not found')));
    }

    final book = bookVM.book!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Discussion'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Book Cover & Basic Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            height: 200,
                            width: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 200,
                              width: 130,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book),
                            ),
                          )
                        : Container(
                            height: 200,
                            width: 130,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book),
                          ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'by ${book.author}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        if (book.genre != null)
                          Chip(
                            label: Text(book.genre!),
                            backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: Colors.deepPurple, fontSize: 12),
                          ),
                        const SizedBox(height: 16),
                        // Reading Status - Now more prominent
                        Row(
                          children: [
                            _statusChip(bookVM, 'want_to_read', 'Want to Read'),
                            const SizedBox(width: 8),
                            _statusChip(bookVM, 'reading', 'Reading'),
                            const SizedBox(width: 8),
                            _statusChip(bookVM, 'finished', 'Finished'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary/Synopsis
                  const Text(
                    'About the Book',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.synopsis ?? book.description ?? 'No description available.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Community Section - THE CORE
                  const Text(
                    'Community Discussion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews & Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => _showAddReviewDialog(context, reviewVM),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  reviewVM.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : reviewVM.reviews.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No reviews yet. Start the conversation!'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviewVM.reviews.length,
                              itemBuilder: (context, index) {
                                final review = reviewVM.reviews[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text('Rating: ${review.rating} ★', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${review.reviewText}\n- ${review.username ?? 'Anonymous'}'),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 24),

                  // Annotations/Quotes Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Book Annotations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => _showAddQuoteDialog(context, quoteVM),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Annotate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  quoteVM.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : quoteVM.quotes.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No annotations yet. Share your favorite parts!'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: quoteVM.quotes.length,
                              itemBuilder: (context, index) {
                                final quote = quoteVM.quotes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '"${quote.quoteText}"',
                                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Page ${quote.pageNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text('- ${quote.username ?? 'Anonymous'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BookDetailViewModel vm, String value, String label) {
    final isSelected = vm.currentStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          vm.updateStatus(value);
        }
      },
    );
  }

  void _showAddQuoteDialog(BuildContext context, QuoteViewModel vm) {
    final textController = TextEditingController();
    final pageController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Annotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Quote Text'),
              maxLines: 3,
            ),
            TextField(
              controller: pageController,
              decoration: const InputDecoration(labelText: 'Page Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.addQuote(
                widget.bookId,
                textController.text.trim(),
                int.tryParse(pageController.text),
                tagController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              );
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annotation saved!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, ReviewViewModel vm) {
    final textController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate this Book'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Your Review'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final success = await vm.addReview(
                      widget.bookId,
                      selectedRating,
                      textController.text.trim(),
                    );
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
