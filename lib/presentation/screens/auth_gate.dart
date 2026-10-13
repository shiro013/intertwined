import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../view_models/auth_view_model.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'reading_preferences_screen.dart';

import 'mfa_challenge_screen.dart';
enum _GateState { checking, signedOut, mfa, onboarding, ready }

/// Pintu masuk aplikasi:
///   tidak ada sesi                    -> AuthScreen
///   akun 2FA, kode belum dimasukkan   -> MfaChallengeScreen

///   akun baru, preferensi belum diisi   -> ReadingPreferencesScreen (sekali saja)
///   selain itu                          -> MainScreen
/// Login, verifikasi kode, dan sign out cukup mengubah sesi; layar
/// berganti otomatis dari sini.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _subscription;
  _GateState _state = _GateState.checking;
  int _evaluationId = 0;

  @override
  void initState() {
    super.initState();
    _evaluate();
    _subscription = _client.auth.onAuthStateChange.listen((_) => _evaluate());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<_GateState> _resolve(AuthViewModel authViewModel) async {
    if (_client.auth.currentSession == null) return _GateState.signedOut;
        // Password benar tidak cukup untuk akun 2FA: kode authenticator dulu.
    if (authViewModel.needsMfaChallenge) return _GateState.mfa;
    if (await authViewModel.needsPreferencesSetup()) return _GateState.onboarding;
    return _GateState.ready;
  }

  Future<void> _evaluate() async {
    final id = ++_evaluationId;
    final authViewModel = context.read<AuthViewModel>();

    final next = await _resolve(authViewModel);
    // hasil lama diabaikan kalau sudah ada event yang lebih baru
    if (!mounted || id != _evaluationId) return;

    // sesi bisa berakhir selama pengecekan berjalan
    final resolved = _client.auth.currentSession == null ? _GateState.signedOut : next;
    if (resolved == _state) return;
    setState(() => _state = resolved);
  }

  void _onPreferencesDone() {
    _evaluationId++; // batalkan pengecekan yang masih berjalan (hasilnya sudah basi)
    if (mounted) setState(() => _state = _GateState.ready);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GateState.checking => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
            _GateState.signedOut => const AuthScreen(),
      _GateState.mfa => MfaChallengeScreen(onVerified: () => _evaluate()),
      _GateState.onboarding => ReadingPreferencesScreen(onDone: _onPreferencesDone),
      _GateState.ready => const MainScreen(),
    };
  }
}
