import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../view_models/community_view_model.dart';

/// Membuat klub berdasarkan TOPIK (mis. "Sci-Fi Lovers"), tanpa harus lewat sebuah
/// buku. Berhasil -> layar ini menutup dan mengembalikan klub yang baru dibuat.
class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<CommunityViewModel>();
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    final group = await vm.createClub(
      name: _nameController.text,
      description: _descriptionController.text,
    );
    if (!mounted) return;

    if (group != null) {
      navigator.pop(group);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(vm.createClubError ?? 'Could not create the club.'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = context.watch<CommunityViewModel>().isCreatingClub;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Club', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.groups, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text(
                  'Start a club around a topic, genre or theme. Other readers can find it '
                  'and join. You will be its admin.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Club name',
                    hintText: 'e.g. Sci-Fi Lovers',
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.length < 3) return 'Use at least 3 characters';
                    if (v.length > 50) return 'Use at most 50 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                    hintText: 'What is this club about?',
                  ),
                ),
                const SizedBox(height: 24),
                creating
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _create,
                        child: const Text('Create Club'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
