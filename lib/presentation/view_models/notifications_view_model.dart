import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationsViewModel(this._repository);

  List<NotificationEntity> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;

  // Logout me-reset pohon widget (lihat main.dart); hindari notify setelah dispose.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<NotificationEntity> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Jumlah yang belum dibaca (untuk lencana di tab Profile).
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Memeriksa notifikasi baru secara berkala selama aplikasi terbuka.
  void startPolling({Duration interval = const Duration(seconds: 60)}) {
    _pollTimer?.cancel();
    loadNotifications(silent: true);
    _pollTimer = Timer.periodic(interval, (_) => loadNotifications(silent: true));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// [silent] = tanpa spinner dan tanpa pesan error (dipakai pemeriksaan berkala).
  Future<void> loadNotifications({bool silent = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _notifications = await _repository.getNotifications(user.id);
      _errorMessage = null;
    } catch (e) {
      if (!silent) _errorMessage = 'Failed to load notifications. Please try again.';
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _repository.markAllAsRead(user.id);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
