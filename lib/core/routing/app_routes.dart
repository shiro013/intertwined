import 'package:flutter/material.dart';
import 'package:intertwined/domain/entities/book_entity.dart';
import 'package:intertwined/presentation/screens/auth_screen.dart';
import 'package:intertwined/presentation/screens/book_detail_screen.dart';
import 'package:intertwined/presentation/screens/catatan_form_screen.dart';
import 'package:intertwined/presentation/screens/error/not_found_screen.dart';
import 'package:intertwined/presentation/screens/home_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String catatanForm = '/catatan-form';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case detail:
        final args = settings.arguments;
        if (args is BookEntity) {
          return MaterialPageRoute(
            builder: (_) => BookDetailScreen(item: args),
          );
        }
        // ignore: dead_code
        return null;
      case catatanForm:
        return MaterialPageRoute<String>(
          builder: (_) => const CatatanFormScreen(),
        );
      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => NotFoundScreen(routeName: settings.name),
    );
  }
}
