import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_flash.dart';
import '../../core/utils/validators.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_widgets.dart';

enum _Step { email, code, newPassword }

/// Reset password lewat kode email: email -> kode -> password baru.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.email;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();

    final ok = await vm.requestPasswordReset(email);
    if (!mounted) return;
    if (ok) {
      // Pesan sama untuk email terdaftar maupun tidak (tidak membocorkan akun).
      setState(() {
        _email = email;
        _step = _Step.code;
      });
    } else {
      _snack(vm.errorMessage ?? 'Could not send the code.', error: true);
    }
  }

  Future<bool> _resendCode() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.requestPasswordReset(_email);
    _snack(
      ok ? 'A new code was sent (if the account exists).' : (vm.errorMessage ?? 'Could not send the code.'),
      error: !ok,
    );
    return ok;
  }

  Future<void> _verifyCode() async {
    if (!_codeKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    FocusScope.of(context).unfocus();

    final ok = await vm.verifyRecoveryCode(_email, _codeController.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _Step.newPassword);
    } else {
      _snack(vm.errorMessage ?? 'Could not verify the code.', error: true);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    final updated = await vm.setNewPassword(_passwordController.text);
    if (!mounted) return;
    if (!updated) {
      _snack(vm.errorMessage ?? 'Could not update your password.', error: true);
      return;
    }

    // Keluarkan semua perangkat, lalu kembali ke login dengan password baru.
    // Sign out me-reset seluruh pohon widget, jadi pesan dititipkan lewat AuthFlash.
    AuthFlash.set('Password updated. Please sign in with your new password.');
    final signedOut = await vm.signOutEverywhere();
    if (signedOut) return; // root me-reset aplikasi ke layar login
    if (mounted) navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.email => _emailStep(vm),
            _Step.code => _codeStep(vm),
            _Step.newPassword => _passwordStep(vm),
          },
        ),
      ),
    );
  }

  Widget _emailStep(AuthViewModel vm) {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Enter the email you registered with and we'll send you a verification code.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _sendCode, child: const Text('Send code')),
        ],
      ),
    );
  }

  Widget _codeStep(AuthViewModel vm) {
    return Form(
      key: _codeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'If an account exists for ${Validators.maskEmail(_email)}, '
            'a verification code is on its way. Enter it below.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          OtpCodeField(controller: _codeController, onSubmitted: (_) => _verifyCode()),
          const SizedBox(height: 16),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _verifyCode, child: const Text('Verify code')),
          ResendCodeButton(onResend: _resendCode),
          TextButton(
            onPressed: () {
              _codeController.clear();
              setState(() => _step = _Step.email);
            },
            child: const Text(
              'Use a different email',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordStep(AuthViewModel vm) {
    return Form(
      key: _passwordKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Code verified. Choose a new password. You will be signed out of '
            'all devices afterwards.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PasswordField(
            controller: _passwordController,
            label: 'New password',
            isNewPassword: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: Validators.password,
          ),
          PasswordStrengthMeter(password: _passwordController.text),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmController,
            label: 'Confirm new password',
            isNewPassword: true,
            onSubmitted: (_) => _savePassword(),
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _savePassword, child: const Text('Update password')),
        ],
      ),
    );
  }
}
