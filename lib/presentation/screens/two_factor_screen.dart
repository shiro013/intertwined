import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../view_models/two_factor_view_model.dart';
import '../widgets/mfa_code_step.dart';

/// Pasang / matikan 2FA dengan aplikasi authenticator (Google Authenticator,
/// Authy, Microsoft Authenticator, 1Password, ...).
class TwoFactorScreen extends StatelessWidget {
  const TwoFactorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TwoFactorViewModel>(
      create: (_) => TwoFactorViewModel(AuthRepository())..load(),
      child: const _TwoFactorView(),
    );
  }
}

class _TwoFactorView extends StatefulWidget {
  const _TwoFactorView();

  @override
  State<_TwoFactorView> createState() => _TwoFactorViewState();
}

class _TwoFactorViewState extends State<_TwoFactorView> {
  final _codeKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : null),
      );
  }

  Future<void> _start(TwoFactorViewModel vm) async {
    final ok = await vm.startEnrollment();
    if (!ok) _snack(vm.errorMessage ?? 'Could not start setup.', error: true);
  }

  Future<void> _confirm(TwoFactorViewModel vm) async {
    if (!_codeKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await vm.confirmEnrollment(_codeController.text);
    if (!mounted) return;
    if (ok) {
      _codeController.clear();
      _snack('Two-factor authentication is now on.');
    } else {
      _codeController.clear();
      _snack(vm.errorMessage ?? 'That code is incorrect.', error: true);
    }
  }

  Future<void> _disable(TwoFactorViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Turn off two-factor authentication?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your account will be protected by your password only.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Turn off', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await vm.disable();
    if (!mounted) return;
    _snack(
      ok ? 'Two-factor authentication is off.' : (vm.errorMessage ?? 'Could not turn it off.'),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TwoFactorViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Two-Factor Authentication',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (vm.status) {
            TwoFactorStatus.loading => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            TwoFactorStatus.error => _errorView(vm),
            TwoFactorStatus.disabled => _disabledView(vm),
            TwoFactorStatus.enrolling => _enrollingView(vm),
            TwoFactorStatus.enabled => _enabledView(vm),
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ views

  Widget _errorView(TwoFactorViewModel vm) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          vm.errorMessage ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: vm.load, child: const Text('Retry')),
      ],
    );
  }

  Widget _disabledView(TwoFactorViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.shield_outlined, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        const Text(
          'Add a second step to signing in',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'After you enter your password, you will also enter a 6-digit code from an '
          'authenticator app on your phone. Even if someone learns your password, '
          'they cannot sign in without your phone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 28),
        vm.isBusy
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ElevatedButton(
                onPressed: () => _start(vm),
                child: const Text('Set up authenticator app'),
              ),
      ],
    );
  }

  Widget _enrollingView(TwoFactorViewModel vm) {
    final enrollment = vm.enrollment!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. Scan this QR code',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Open an authenticator app (Google Authenticator, Authy, Microsoft '
          'Authenticator, ...) and scan the code.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: enrollment.uri,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Can't scan? Enter this key in the app instead:",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  _groupSecret(enrollment.secret),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy key',
                icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: enrollment.secret));
                  _snack('Key copied.');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
          ),
          child: const Text(
            'Save this key somewhere safe (a password manager works well). If you lose '
            'your phone, it is the only way to restore your authenticator and get back '
            'into your account.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '2. Enter the 6-digit code',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        MfaCodeStep(
          formKey: _codeKey,
          controller: _codeController,
          isLoading: vm.isBusy,
          onSubmit: () => _confirm(vm),
          message: 'Type the code your app shows for Intertwined to finish setup.',
          buttonLabel: 'Turn on two-factor authentication',
          footer: TextButton(
            onPressed: vm.isBusy ? null : vm.cancelEnrollment,
            child: const Text(
              'Cancel setup',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _enabledView(TwoFactorViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user, size: 56, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Two-factor authentication is on',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You will be asked for a code from your authenticator app each time you sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        const Text(
          'If you lose access to your authenticator app and have not saved your setup '
          'key, you will be locked out of your account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDisabled, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 28),
        vm.isBusy
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : OutlinedButton(
                onPressed: () => _disable(vm),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text(
                  'Turn off two-factor authentication',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
      ],
    );
  }

  /// "JBSWY3DPEHPK3PXP" -> "JBSW Y3DP EHPK 3PXP" (lebih mudah diketik).
  String _groupSecret(String secret) {
    final clean = secret.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}
