import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_flash.dart';
import '../../core/utils/validators.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'verify_code_screen.dart';

/// Login (username ATAU email + password) dan pendaftaran (username + email +
/// password). Navigasi ke aplikasi dilakukan oleh AuthGate begitu sesi terbentuk.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController =
      TextEditingController(); // login: username/email
  final _usernameController = TextEditingController(); // register
  final _emailController = TextEditingController(); // register
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    final notice = AuthFlash.take();
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snack(notice);
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  void _toggleMode() {
    context.read<AuthViewModel>().clearError();
    _formKey.currentState?.reset();
    _passwordController.clear();
    _confirmController.clear();
    setState(() => _isLogin = !_isLogin);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    FocusScope.of(context).unfocus();

    if (_isLogin) {
      final outcome = await vm.signIn(
        _identifierController.text,
        _passwordController.text,
      );
      if (!mounted) return;

      switch (outcome) {
        case LoginOutcome.success:
          break; // AuthGate menampilkan MainScreen
        case LoginOutcome.needsVerification:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyCodeScreen(
                email: vm.pendingEmail!,
                sendCodeOnOpen: true, // login tidak mengirim kode otomatis
              ),
            ),
          );
        case LoginOutcome.failed:
          _snack(vm.errorMessage ?? 'Could not sign in.', error: true);
      }
      return;
    }

    final email = _emailController.text.trim();
    final outcome = await vm.signUp(
      username: _usernameController.text.trim(),
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;

    switch (outcome) {
      case SignUpOutcome.needsVerification:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
        );
      case SignUpOutcome.failed:
        _snack(
          vm.errorMessage ?? 'Could not create your account.',
          error: true,
        );
    }
  }

  void _openForgotPassword() {
    final id = _identifierController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: Validators.looksLikeEmail(id) ? id : '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Intertwined',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect your reading soul',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),
                    if (_isLogin)
                      ..._loginFields(vm)
                    else
                      ..._registerFields(vm),
                    const SizedBox(height: 24),
                    vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            child: Text(
                              _isLogin ? 'Sign In' : 'Create Account',
                            ),
                          ),
                    TextButton(
                      onPressed: vm.isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? 'New here? Create an account'
                            : 'Already have an account? Sign In',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _loginFields(AuthViewModel vm) {
    return [
      TextFormField(
        controller: _identifierController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Username or email'),
        validator: (v) =>
            (v ?? '').trim().isEmpty ? 'Enter your username or email' : null,
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: _passwordController,
        validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
        onSubmitted: (_) => _submit(),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: vm.isLoading ? null : _openForgotPassword,
          child: const Text(
            'Forgot password?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    ];
  }

  List<Widget> _registerFields(AuthViewModel vm) {
    return [
      TextFormField(
        controller: _usernameController,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        autofillHints: const [AutofillHints.newUsername],
        decoration: const InputDecoration(
          labelText: 'Username',
          helperText: '3-20 characters: letters, numbers, "_" or "."',
        ),
        validator: Validators.username,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(
          labelText: 'Email',
          helperText: "We'll send a verification code to this address",
        ),
        validator: Validators.email,
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: _passwordController,
        isNewPassword: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}), // memperbarui meter kekuatan
        validator: (v) =>
            Validators.password(v, username: _usernameController.text),
      ),
      PasswordStrengthMeter(password: _passwordController.text),
      const SizedBox(height: 16),
      PasswordField(
        controller: _confirmController,
        label: 'Confirm password',
        isNewPassword: true,
        onSubmitted: (_) => _submit(),
        validator: (v) =>
            v != _passwordController.text ? 'Passwords do not match' : null,
      ),
    ];
  }
}
