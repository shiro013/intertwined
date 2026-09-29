import 'package:flutter/material.dart';

import '../../domain/entities/book_entity.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';

class BookDetailScreen extends StatefulWidget {
  final BookEntity item;

  const BookDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  String? _catatan;

  Future<void> _bukaFormCatatan() async {
    final hasil = await Navigator.pushNamed<String>(
      context,
      AppRoutes.catatanForm,
    );
    if (!mounted || hasil == null) return;
    setState(() => _catatan = hasil);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan berhasil disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${book.author}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            book.description,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.justify,
          ),
          const Divider(height: 32),
          Text(
            _catatan == null ? 'Belum ada catatan.' : 'Catatan: $_catatan',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _bukaFormCatatan,
            icon: const Icon(Icons.edit_note),
            label: const Text('Tulis Catatan'),
          ),
        ],
      ),
    );
  }
}
