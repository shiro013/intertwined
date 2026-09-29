import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    if (isLogin) {
      final success = await authVM.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (success) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      final success = await authVM.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created! Please verify email.')),
        );
      }
    }

    if (authVM.errorMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'An unexpected error occurred'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Intertwined',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge
                        ?.copyWith(color: AppColors.primary, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect your reading soul',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  if (!isLogin) ...[
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) => Validators.requiredField(value, fieldName: 'Username'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  authVM.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(isLogin ? 'Sign In' : 'Create Account'),
                        ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
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
    );
  }
}
