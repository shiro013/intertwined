import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import 'auth_widgets.dart';

/// Isi satu langkah "masukkan kode authenticator": penjelasan, kolom 6 digit,
/// tombol verifikasi. Dipakai di layar login (2FA), reset password, dan
/// ganti password, supaya tampilannya sama di mana-mana.
class MfaCodeStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String message;
  final String buttonLabel;

  /// Widget tambahan di bawah tombol (mis. tautan "Sign out").
  final Widget? footer;

  const MfaCodeStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    this.message =
        'Your account is protected with two-factor authentication. '
        'Enter the 6-digit code shown in your authenticator app.',
    this.buttonLabel = 'Verify',
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          OtpCodeField(
            controller: controller,
            label: 'Authenticator code',
            maxLength: 6,
            autofocus: true,
            validator: Validators.otpCode,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: onSubmit, child: Text(buttonLabel)),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}
