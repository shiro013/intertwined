import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/supabase_config.dart';
import 'core/routing/app_routes.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/home_view_model.dart';
import 'presentation/view_models/book_detail_view_model.dart';
import 'presentation/view_models/library_view_model.dart';
import 'presentation/view_models/community_view_model.dart';
import 'presentation/view_models/profile_view_model.dart';
import 'presentation/view_models/quote_view_model.dart';
import 'presentation/view_models/notifications_view_model.dart';
import 'data/repositories/mock/mock_book_repository.dart';
import 'data/repositories/mock/mock_auth_repository.dart';
import 'data/repositories/mock/mock_profile_repository.dart';
import 'data/repositories/community_repository_impl.dart';
import 'data/repositories/feed_repository_impl.dart';
import 'data/repositories/quote_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization is kept for compatibility but we'll use mocks
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed (expected in dummy mode): $e');
  }

  // Inject Mock Repositories for the exercises
  final bookRepository = MockBookRepository();
  final authRepository = MockAuthRepository();
  final profileRepository = MockProfileRepository();

  // Using real implementations for others but they are decoupled from logic in the exercises
  final communityRepository = CommunityRepositoryImpl();
  final feedRepository = FeedRepositoryImpl();
  final quoteRepository = QuoteRepositoryImpl();
  final notificationRepository = NotificationRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(bookRepository, feedRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BookDetailViewModel(bookRepository: bookRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityViewModel(communityRepository),
        ),
        ChangeNotifierProvider(create: (_) => LibraryViewModel(bookRepository)),
        ChangeNotifierProvider(create: (_) => ProfileViewModel(profileRepository)),
        ChangeNotifierProvider(create: (_) => QuoteViewModel(quoteRepository)),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel(notificationRepository)),
      ],
      child: const IntertwinedApp(),
    ),
  );
}

class IntertwinedApp extends StatelessWidget {
  const IntertwinedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intertwined',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}
