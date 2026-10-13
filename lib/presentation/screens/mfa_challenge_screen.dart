import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/mfa_code_step.dart';

/// Layar setelah password benar untuk akun yang memakai 2FA.
/// AuthGate menampilkannya selama sesi masih AAL1; aplikasi tidak bisa dibuka
/// sebelum kode authenticator benar.
class MfaChallengeScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const MfaChallengeScreen({super.key, required this.onVerified});

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    FocusScope.of(context).unfocus();

    final ok = await vm.verifyMfaCode(_codeController.text);
    if (!mounted) return;
    if (ok) {
      widget.onVerified();
      return;
    }
    _codeController.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'That code is incorrect.'),
          backgroundColor: AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_outlined, size: 56, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Two-factor authentication',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MfaCodeStep(
                    formKey: _formKey,
                    controller: _codeController,
                    isLoading: vm.isLoading,
                    onSubmit: _verify,
                    buttonLabel: 'Verify and continue',
                    footer: TextButton(
                      onPressed: vm.isLoading ? null : () => vm.signOut(),
                      child: const Text(
                        'Sign out',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
