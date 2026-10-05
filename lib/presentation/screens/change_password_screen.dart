import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_widgets.dart';

enum _Step { currentPassword, code, newPassword }

/// Ganti password saat sudah login, dalam 3 langkah yang harus dilalui berurutan:
///   1. password saat ini  ->  kode dikirim ke email
///   2. kode diperiksa SERVER (salah = berhenti di sini)
///   3. password baru (baru tampil setelah kode terbukti benar)
/// Perangkat lain otomatis dikeluarkan setelahnya.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _newKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.currentPassword;

  @override
  void dispose() {
    _currentController.dispose();
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

  /// Langkah 1 -> 2
  Future<void> _sendCode() async {
    if (!_currentKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    FocusScope.of(context).unfocus();

    if (!await vm.verifyCurrentPassword(_currentController.text)) {
      _snack(vm.errorMessage ?? 'Incorrect password.', error: true);
      return;
    }
    if (!await vm.sendChangePasswordCode()) {
      _snack(vm.errorMessage ?? 'Could not send the code.', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _step = _Step.code);
  }

  Future<bool> _resendCode() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.sendChangePasswordCode();
    _snack(
      ok ? 'A new code was sent to your email.' : (vm.errorMessage ?? 'Could not send the code.'),
      error: !ok,
    );
    return ok;
  }

  /// Langkah 2 -> 3: hanya lanjut jika server menyatakan kode benar.
  Future<void> _verifyCode() async {
    if (!_codeKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    FocusScope.of(context).unfocus();

    final ok = await vm.verifyChangePasswordCode(_codeController.text);
    if (!mounted) return;
    if (!ok) {
      _codeController.clear();
      _snack(vm.errorMessage ?? 'That code is incorrect.', error: true);
      return;
    }
    setState(() => _step = _Step.newPassword);
  }

  /// Langkah 3: simpan password baru.
  Future<void> _save() async {
    if (!_newKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    final ok = await vm.changePassword(_passwordController.text);
    if (!mounted) return;
    if (!ok) {
      _snack(vm.errorMessage ?? 'Could not change your password.', error: true);
      return;
    }

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password updated. Other devices have been signed out.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final email = vm.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.currentPassword => _currentStep(vm, email),
            _Step.code => _codeStep(vm, email),
            _Step.newPassword => _newStep(vm),
          },
        ),
      ),
    );
  }

  Widget _currentStep(AuthViewModel vm, String? email) {
    return Form(
      key: _currentKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            email == null
                ? 'Confirm your current password. For your security we will then email you a verification code.'
                : 'Confirm your current password. For your security we will then email a verification code to ${Validators.maskEmail(email)}.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PasswordField(
            controller: _currentController,
            label: 'Current password',
            onSubmitted: (_) => _sendCode(),
            validator: (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
          ),
          const SizedBox(height: 24),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _sendCode, child: const Text('Send code')),
        ],
      ),
    );
  }

  Widget _codeStep(AuthViewModel vm, String? email) {
    return Form(
      key: _codeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            email == null
                ? 'Enter the verification code we emailed you.'
                : 'Enter the verification code sent to ${Validators.maskEmail(email)}.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          OtpCodeField(controller: _codeController, onSubmitted: (_) => _verifyCode()),
          const SizedBox(height: 16),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _verifyCode, child: const Text('Verify code')),
          ResendCodeButton(onResend: _resendCode),
        ],
      ),
    );
  }

  Widget _newStep(AuthViewModel vm) {
    return Form(
      key: _newKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Code verified. Choose a new password. Your other devices will be signed out.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PasswordField(
            controller: _passwordController,
            label: 'New password',
            isNewPassword: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final problem = Validators.password(v);
              if (problem != null) return problem;
              if (v == _currentController.text) {
                return 'Your new password must be different from the current one';
              }
              return null;
            },
          ),
          PasswordStrengthMeter(password: _passwordController.text),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmController,
            label: 'Confirm new password',
            isNewPassword: true,
            onSubmitted: (_) => _save(),
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _save, child: const Text('Update password')),
        ],
      ),
    );
  }
}
