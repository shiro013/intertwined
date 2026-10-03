import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationsViewModel(this._repository);

  List<NotificationEntity> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationEntity> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(user.id);
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
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
