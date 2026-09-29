import 'package:flutter/material.dart';
import 'package:intertwined/core/routing/app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  final String? routeName;
  final String message;
  const NotFoundScreen({
    super.key,
    this.routeName,
    this.message = 'Halaman yang kamu tuju belum tersedia.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 72),
              const SizedBox(height: 8),
              Text('404', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (routeName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Route: $routeName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
