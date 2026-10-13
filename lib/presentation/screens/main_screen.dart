import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'community_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import '../view_models/notifications_view_model.dart';
import '../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final NotificationsViewModel _notifications;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CommunityScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Periksa notifikasi baru sekarang dan tiap 60 detik selama aplikasi terbuka.
    _notifications = context.read<NotificationsViewModel>();
    _notifications.startPolling();
  }

  @override
  void dispose() {
    _notifications.stopPolling();
    super.dispose();
  }

  /// Lencana angka belum-dibaca di ikon tab.
  Widget _withBadge(Widget icon, int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsViewModel>().unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Community'),
          const BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Library'),
          BottomNavigationBarItem(
            icon: _withBadge(const Icon(Icons.person_outline), unread),
            activeIcon: _withBadge(const Icon(Icons.person), unread),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
