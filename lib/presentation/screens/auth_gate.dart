import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'main_screen.dart';

/// Pintu masuk aplikasi: ada sesi -> MainScreen, tidak ada -> AuthScreen.
/// Login, verifikasi kode, dan sign out cukup mengubah sesi; layar berganti
/// otomatis dari sini (tidak perlu Navigator.pushReplacement manual).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, _) {
        return client.auth.currentSession != null
            ? const MainScreen()
            : const AuthScreen();
      },
    );
  }
}
