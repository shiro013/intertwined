import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_widgets.dart';

/// Hapus akun permanen. Syarat: password benar + mengetik DELETE.
/// Berhasil -> sesi dibersihkan dan aplikasi kembali ke layar login.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    final ok = await vm.deleteAccount(_passwordController.text);
    if (ok) {
      // Sign out me-reset seluruh pohon widget ke layar login. Kalau karena
      // sesuatu itu tidak terjadi, tutup layar ini supaya tidak menggantung.
      if (mounted) navigator.popUntil((route) => route.isFirst);
      return;
    }
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Could not delete your account.'),
          backgroundColor: AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.7)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'This cannot be undone',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your account and everything linked to it will be permanently '
                        'deleted:\n'
                        '\u2022 your profile and photo\n'
                        '\u2022 your reviews, ratings and quotes\n'
                        '\u2022 your bookmarks and reading progress\n'
                        '\u2022 your discussions and comments\n'
                        '\u2022 your followers, following and likes\n'
                        '\u2022 your notifications\n\n'
                        'Clubs you created stay open for their other members.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _passwordController,
                  label: 'Confirm your password',
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _delete(),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
                  validator: (v) =>
                      Validators.isDeleteConfirmation(v) ? null : 'Type DELETE to confirm',
                ),
                const SizedBox(height: 28),
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.error))
                    : ElevatedButton(
                        onPressed: _delete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete my account permanently'),
                      ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Keep my account',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
