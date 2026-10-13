import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'two_factor_screen.dart';

/// Semua pengaturan di sini nyata dan berfungsi.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // status 2FA bisa berubah di layar tadi
  }

  @override
  Widget build(BuildContext context) {
    final mfaOn = context.read<AuthViewModel>().hasMfaEnabled;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text(
              'Privacy & Security',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Account Security'),
                  const SizedBox(height: 16),
                  _buildSettingSection([
                    _buildActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () => _open(const ChangePasswordScreen()),
                    ),
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                    _buildActionTile(
                      icon: mfaOn ? Icons.verified_user : Icons.security,
                      iconColor: mfaOn ? AppColors.success : null,
                      title: 'Two-Factor Authentication',
                      subtitle: mfaOn ? 'On' : 'Off',
                      onTap: () => _open(const TwoFactorScreen()),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Text(
                    'Your profile, quotes and reviews are visible to other Intertwined readers.',
                    style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle(context, 'Data Management'),
                  const SizedBox(height: 16),
                  _buildSettingSection([
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      titleColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: () => _open(const DeleteAccountScreen()),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSettingSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? AppColors.textPrimary),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
