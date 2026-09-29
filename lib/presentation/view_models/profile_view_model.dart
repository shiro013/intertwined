import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileViewModel(this._profileRepository);

  UserEntity? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _profileRepository.getUserProfile(currentUser.id);
      if (_user == null) {
        _errorMessage = 'Profile not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String fullName, String bio, List<String> favoriteGenres) async {
    if (_user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.updateProfile(
        _user!.id,
        fullName: fullName,
        bio: bio,
        favoriteGenres: favoriteGenres,
      );

      // Refresh local user state
      _user = await _profileRepository.getUserProfile(_user!.id);
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
