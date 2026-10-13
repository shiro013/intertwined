import 'package:flutter/material.dart';

import '../screens/user_profile_screen.dart';

/// Buka profil publik seorang pengguna. Aman dipanggil dengan id kosong (diabaikan).
void openUserProfile(BuildContext context, String? userId) {
  if (userId == null || userId.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
  );
}
