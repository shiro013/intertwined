import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/feed_viewmodel.dart';
import '../../models/quote.dart';
import '../../models/review.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedViewModel>().loadFeed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedVM = Provider.of<FeedViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Feed'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => feedVM.refreshFeed(),
        child: feedVM.isLoading
            ? const Center(child: CircularProgressIndicator())
            : feedVM.feedItems.isEmpty
            ? const Center(child: Text('No activities yet. Start reading!'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: feedVM.feedItems.length,
                itemBuilder: (context, index) {
                  final item = feedVM.feedItems[index];
                  final type = item.type;
                  final data = item.data;

                  Quote? quote = data is Quote ? data : null;
                  Review? review = data is Review ? data : null;

                  final username = (data as dynamic).username ?? 'Anonymous';
                  final createdAt = item.createdAt;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: (data as dynamic).avatarUrl != null
                                    ? NetworkImage((data as dynamic).avatarUrl)
                                    : null,
                                child: (data as dynamic).avatarUrl == null
                                    ? Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : 'U',
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                createdAt.length >= 10
                                    ? createdAt.substring(0, 10)
                                    : createdAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (type == 'quote' && quote != null) ...[
                            Text(
                              '"${quote.quoteText}"',
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'from ${quote.username ?? 'Unknown Book'}', // Assuming book title might be in the model or handled separately
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (type == 'review' && review != null) ...[
                            Row(
                              children: [
                                Text(
                                  'Rating: ${review.rating} ★',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.reviewText,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'on ${review.username ?? 'Unknown Book'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
