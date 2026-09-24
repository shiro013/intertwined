import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/group_viewmodel.dart';
import 'core/supabase_client.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/book_detail_viewmodel.dart';
import 'viewmodels/quote_viewmodel.dart';
import 'viewmodels/review_viewmodel.dart';
import 'viewmodels/library_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/books/book_detail_screen.dart';
import 'views/library/library_screen.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'views/feed/feed_screen.dart';
import 'views/main/main_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove 'await' from initialize to prevent blocking the app startup
  // We will handle initialization errors inside the app
  SupabaseConfig.initialize().catchError((e) {
    debugPrint('CRITICAL: Supabase background initialization failed: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => BookDetailViewModel()),
        ChangeNotifierProvider(create: (_) => QuoteViewModel()),
        ChangeNotifierProvider(create: (_) => ReviewViewModel()),
        ChangeNotifierProvider(create: (_) => LibraryViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => GroupViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intertwined',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainContainer(),
        '/book-detail': (context) => const BookDetailRouteWrapper(),
        '/library': (context) => const LibraryScreen(),
        '/feed': (context) => const FeedScreen(),
      },
    );
  }
}

// Wrapper for passing bookId to BookDetailScreen
class BookDetailRouteWrapper extends StatelessWidget {
  const BookDetailRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final bookId = ModalRoute.of(context)!.settings.arguments as String;
    return BookDetailScreen(bookId: bookId);
  }
}
