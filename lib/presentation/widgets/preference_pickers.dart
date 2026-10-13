import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const List<String> kGenreOptions = [
  'Fiction',
  'Non-Fiction',
  'Fantasy',
  'Science Fiction',
  'Mystery',
  'Thriller',
  'Romance',
  'Horror',
  'Historical Fiction',
  'Biography',
  'Self-Help',
  'Business',
  'Science',
  'Technology',
  'Psychology',
  'Philosophy',
  'Poetry',
  'Comics & Manga',
  'Young Adult',
  'Religion',
];

const int kMaxGenres = 8;
const int kMaxAuthors = 10;
const int kMaxAuthorLength = 50;

String normalizeTag(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Pilih genre favorit dengan chip (maksimal [maxSelected]).
/// Genre lama yang diketik bebas sebelumnya tetap tampil sebagai chip terpilih.
class GenreChipPicker extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final int maxSelected;

  const GenreChipPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.maxSelected = kMaxGenres,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ...kGenreOptions,
      ...selected.where((g) => !kGenreOptions.contains(g)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final genre in options)
          FilterChip(
            label: Text(genre),
            selected: selected.contains(genre),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            labelStyle: TextStyle(
              fontSize: 13,
              color: selected.contains(genre) ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              if (selected.contains(genre)) {
                onChanged(selected.where((s) => s != genre).toList());
              } else if (selected.length >= maxSelected) {
                _toast(context, 'You can pick up to $maxSelected genres.');
              } else {
                onChanged([...selected, genre]);
              }
            },
          ),
      ],
    );
  }
}

/// Tambah penulis favorit: ketik nama lalu Enter / koma / tombol +.
class AuthorTagInput extends StatefulWidget {
  final List<String> authors;
  final ValueChanged<List<String>> onChanged;
  final int maxAuthors;

  const AuthorTagInput({
    super.key,
    required this.authors,
    required this.onChanged,
    this.maxAuthors = kMaxAuthors,
  });

  @override
  State<AuthorTagInput> createState() => _AuthorTagInputState();
}

class _AuthorTagInputState extends State<AuthorTagInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final next = [...widget.authors];

    for (final piece in raw.split(',')) {
      final name = normalizeTag(piece);
      if (name.isEmpty) continue;
      if (name.length > kMaxAuthorLength) {
        _toast(context, 'Author names can be up to $kMaxAuthorLength characters.');
        continue;
      }
      if (next.any((a) => a.toLowerCase() == name.toLowerCase())) continue;
      if (next.length >= widget.maxAuthors) {
        _toast(context, 'You can add up to ${widget.maxAuthors} authors.');
        break;
      }
      next.add(name);
    }

    _controller.clear();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: AppColors.textPrimary),
          onSubmitted: _add,
          onChanged: (value) {
            if (value.contains(',')) _add(value);
          },
          decoration: InputDecoration(
            hintText: 'Type an author and press Enter',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            suffixIcon: IconButton(
              tooltip: 'Add author',
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () => _add(_controller.text),
            ),
          ),
        ),
        if (widget.authors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final author in widget.authors)
                Chip(
                  label: Text(
                    author,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  deleteIconColor: AppColors.textSecondary,
                  onDeleted: () => widget.onChanged(
                    widget.authors.where((a) => a != author).toList(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
