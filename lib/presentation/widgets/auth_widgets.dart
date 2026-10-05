import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';

/// Kolom password dengan tombol tampil/sembunyikan.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final bool isNewPassword;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.isNewPassword = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: [
        widget.isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Empat batang kekuatan password + label.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final score = Validators.passwordStrength(password);
    if (password.isEmpty) return const SizedBox.shrink();

    const labels = ['Too short', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = switch (score) {
      <= 1 => AppColors.error,
      2 => Colors.orange,
      3 => Colors.lightGreen,
      _ => Colors.green,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 1; i <= 4; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= score ? color : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            labels[score],
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Kolom kode OTP dari email. Panjang kode dibuat fleksibel (6-10 digit) karena
/// "Email OTP Length" bisa diubah di Supabase Dashboard.
class OtpCodeField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const OtpCodeField({super.key, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 10,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: const InputDecoration(
        labelText: 'Verification code',
        counterText: '',
      ),
      validator: (value) {
        final v = (value ?? '').trim();
        if (v.length < 6) return 'Enter the code from your email';
        return null;
      },
    );
  }
}

/// "Kirim ulang kode" dengan hitung mundur supaya tidak bisa di-spam.
/// [onResend] mengembalikan true kalau kode benar-benar terkirim.
class ResendCodeButton extends StatefulWidget {
  final Future<bool> Function() onResend;
  final int cooldownSeconds;

  /// true = hitung mundur dimulai segera (karena kode baru saja dikirim).
  final bool startCoolingDown;

  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 60,
    this.startCoolingDown = true,
  });

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _remaining = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.startCoolingDown) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final ok = await widget.onResend();
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining <= 0 && !_sending;
    return TextButton(
      onPressed: canResend ? _resend : null,
      child: Text(
        _sending
            ? 'Sending…'
            : _remaining > 0
                ? 'Resend code in ${_remaining}s'
                : 'Resend code',
        style: TextStyle(
          color: canResend ? AppColors.primary : AppColors.textDisabled,
        ),
      ),
    );
  }
}
