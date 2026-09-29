import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  String _profileVisibility = 'Public';
  final List<String> _visibilityOptions = ['Public', 'Private', 'Friends Only'];

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent. All your collection and discussions will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: const Text(
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
                  Text(
                    'Account Visibility',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingSection([
                    ListTile(
                      title: const Text(
                        'Profile Visibility',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      trailing: DropdownButton<String>(
                        value: _profileVisibility,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        items: _visibilityOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _profileVisibility = val!),
                      ),
                    ),
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                    _buildActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                    _buildActionTile(
                      icon: Icons.security,
                      title: 'Two-Factor Authentication',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingSection([
                    _buildActionTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Clear App Cache',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      titleColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: _confirmDeleteAccount,
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

  Widget _buildSettingSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
