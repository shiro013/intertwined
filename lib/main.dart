import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/supabase_config.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/home_view_model.dart';
import 'presentation/view_models/book_detail_view_model.dart';
import 'presentation/view_models/library_view_model.dart';
import 'presentation/view_models/community_view_model.dart';
import 'presentation/view_models/profile_view_model.dart';
import 'presentation/view_models/quote_view_model.dart';
import 'presentation/view_models/notifications_view_model.dart';
import 'data/repositories/book_repository_impl.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/repositories/community_repository_impl.dart';
import 'data/repositories/feed_repository_impl.dart';
import 'data/repositories/quote_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'presentation/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseKey,
  );

  runApp(const IntertwinedRoot());
}

/// Akar aplikasi. Menyimpan semua ViewModel milik SATU sesi login.
///
/// Begitu user sign out (atau sesinya kedaluwarsa), `_generation` naik dan seluruh
/// pohon provider dibuat ulang. Tanpa ini, data akun sebelumnya (library, klub,
/// profil) masih tertinggal di memori dan bisa terlihat oleh akun berikutnya
/// yang login di perangkat yang sama.
class IntertwinedRoot extends StatefulWidget {
  const IntertwinedRoot({super.key});

  @override
  State<IntertwinedRoot> createState() => _IntertwinedRootState();
}

class _IntertwinedRootState extends State<IntertwinedRoot> {
  // Repository tidak menyimpan data pengguna, aman dipakai lintas sesi.
  final _bookRepository = BookRepositoryImpl();
  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepositoryImpl();
  final _communityRepository = CommunityRepositoryImpl();
  final _feedRepository = FeedRepositoryImpl();
  final _quoteRepository = QuoteRepositoryImpl();
  final _notificationRepository = NotificationRepositoryImpl();

  late LibraryViewModel _libraryViewModel = LibraryViewModel(_bookRepository);
  int _generation = 0;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) _resetSession();
    });
  }

  void _resetSession() {
    final old = _libraryViewModel;
    setState(() {
      _generation++;
      _libraryViewModel = LibraryViewModel(_bookRepository);
    });
    // Dibuang setelah frame, saat pohon lama sudah benar-benar dilepas.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _refreshLibrary() => _libraryViewModel.loadLibrary(silent: true);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(_generation),
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(_authRepository)),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(_bookRepository, _feedRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BookDetailViewModel(
            bookRepository: _bookRepository,
            communityRepository: _communityRepository,
            quoteRepository: _quoteRepository,
            feedRepository: _feedRepository,
            onLibraryChanged: _refreshLibrary,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityViewModel(
            _communityRepository,
            onMembershipChanged: _refreshLibrary,
          ),
        ),
        ChangeNotifierProvider<LibraryViewModel>.value(value: _libraryViewModel),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(_profileRepository),
        ),
        ChangeNotifierProvider(create: (_) => QuoteViewModel(_quoteRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationsViewModel(_notificationRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Intertwined',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}
