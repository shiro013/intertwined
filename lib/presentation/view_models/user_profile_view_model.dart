import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/follow_entities.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/follow_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/quote_repository.dart';

/// Profil publik satu pengguna + tombol Follow. Satu instance per layar profil
/// (dibuat di UserProfileScreen), jadi membuka profil di atas profil lain aman.
class UserProfileViewModel extends ChangeNotifier {
  final String userId;
  final ProfileRepository _profileRepository;
  final FollowRepository _followRepository;
  final QuoteRepository _quoteRepository;

  UserProfileViewModel({
    required this.userId,
    required ProfileRepository profiles,
    required FollowRepository follows,
    required QuoteRepository quotes,
  })  : _profileRepository = profiles,
        _followRepository = follows,
        _quoteRepository = quotes;

  UserEntity? _user;
  ProfileStats _stats = const ProfileStats();
  List<QuoteEntity> _quotes = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;
  String? _errorMessage;

  // Layar bisa ditutup saat request masih berjalan.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  UserEntity? get user => _user;
  ProfileStats get stats => _stats;
  List<QuoteEntity> get quotes => _quotes;
  bool get isLoading => _isLoading;
  bool get isFollowing => _isFollowing;
  bool get isTogglingFollow => _isTogglingFollow;
  String? get errorMessage => _errorMessage;
  void clearError() => _errorMessage = null;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  bool get isMe => _currentUserId == userId;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait<Object?>([
        _profileRepository.getUserProfile(userId),
        _followRepository.getStats(userId),
        isMe ? Future.value(false) : _followRepository.isFollowing(userId),
        _quoteRepository.fetchUserQuotes(userId).catchError((Object e) {
          debugPrint('Load user quotes failed: $e');
          return <QuoteEntity>[];
        }),
      ]);
      _user = results[0] as UserEntity?;
      _stats = results[1] as ProfileStats;
      _isFollowing = results[2] as bool;
      _quotes = results[3] as List<QuoteEntity>;
    } catch (e) {
      debugPrint('Load profile $userId failed: $e');
      if (!silent || _user == null) {
        _errorMessage = 'Could not load this profile. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// true hanya kalau perubahan benar-benar tersimpan di server.
  Future<bool> toggleFollow() async {
    if (isMe || _isTogglingFollow || _user == null) return false;

    final wasFollowing = _isFollowing;
    final before = _stats;

    // Optimistic: tombol & angka langsung berubah, dikembalikan kalau gagal.
    _isTogglingFollow = true;
    _isFollowing = !wasFollowing;
    _stats = _stats.copyWith(
      followers: math.max(0, _stats.followers + (wasFollowing ? -1 : 1)),
    );
    notifyListeners();

    try {
      if (wasFollowing) {
        await _followRepository.unfollow(userId);
      } else {
        await _followRepository.follow(userId);
      }
      return true;
    } catch (e) {
      debugPrint('toggleFollow error: $e');
      _isFollowing = wasFollowing;
      _stats = before;
      _errorMessage = wasFollowing
          ? 'Could not unfollow. Please try again.'
          : 'Could not follow. Please try again.';
      return false;
    } finally {
      _isTogglingFollow = false;
      notifyListeners();
    }
  }
}
