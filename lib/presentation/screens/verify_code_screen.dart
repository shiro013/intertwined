import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_widgets.dart';

/// Memasukkan kode verifikasi yang dikirim ke email setelah mendaftar.
/// Kode benar -> sesi terbentuk -> AuthGate menampilkan MainScreen.
class VerifyCodeScreen extends StatefulWidget {
  final String email;

  /// true bila kode belum dikirim (mis. user belum terverifikasi mencoba login).
  final bool sendCodeOnOpen;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    this.sendCodeOnOpen = false,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sendCodeOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resend());
    }
  }

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

  Future<bool> _resend() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.resendSignupCode(widget.email);
    _snack(
      ok ? 'A new code was sent to ${Validators.maskEmail(widget.email)}' : (vm.errorMessage ?? 'Could not send the code.'),
      error: !ok,
    );
    return ok;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    final ok = await vm.verifySignupCode(widget.email, _codeController.text);
    if (!mounted) return;

    if (ok) {
      // Sesi sudah terbentuk; AuthGate (home route) kini menampilkan MainScreen.
      // Tutup layar-layar auth yang menutupinya.
      navigator.popUntil((route) => route.isFirst);
    } else {
      _snack(vm.errorMessage ?? 'Could not verify the code.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
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
                const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  'Check your email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification code to\n${Validators.maskEmail(widget.email)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                OtpCodeField(controller: _codeController, onSubmitted: (_) => _verify()),
                const SizedBox(height: 16),
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _verify, child: const Text('Verify')),
                ResendCodeButton(
                  onResend: _resend,
                  startCoolingDown: !widget.sendCodeOnOpen,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Didn't get it? Check your spam folder. If this email already has "
                  'an account, sign in or use "Forgot password?" instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
