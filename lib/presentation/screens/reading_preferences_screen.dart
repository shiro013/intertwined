import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/preference_pickers.dart';

/// Ditampilkan sekali setelah login pertama (lihat AuthGate): pilih genre dan
/// penulis favorit untuk rekomendasi buku. Boleh dilewati, dan bisa diubah
/// kapan saja lewat Profile -> Edit.
class ReadingPreferencesScreen extends StatefulWidget {
  final VoidCallback onDone;

  const ReadingPreferencesScreen({super.key, required this.onDone});

  @override
  State<ReadingPreferencesScreen> createState() => _ReadingPreferencesScreenState();
}

class _ReadingPreferencesScreenState extends State<ReadingPreferencesScreen> {
  List<String> _genres = [];
  List<String> _authors = [];

  Future<void> _finish({required bool skip}) async {
    final vm = context.read<ProfileViewModel>();
    final ok = skip
        ? await vm.skipPreferences()
        : await vm.savePreferences(favoriteGenres: _genres, favoriteAuthors: _authors);
    if (!mounted) return;

    if (ok) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileViewModel>().isSaving;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_stories, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'What do you love to read?',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick your favorite genres and authors so we can recommend books '
                      'you will enjoy. You can change this any time in your profile.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Genres (${_genres.length}/$kMaxGenres)',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GenreChipPicker(
                      selected: _genres,
                      onChanged: (value) => setState(() => _genres = value),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Favorite authors',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthorTagInput(
                      authors: _authors,
                      onChanged: (value) => setState(() => _authors = value),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  saving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () => _finish(skip: false),
                          child: const Text('Continue'),
                        ),
                  TextButton(
                    onPressed: saving ? null : () => _finish(skip: true),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
