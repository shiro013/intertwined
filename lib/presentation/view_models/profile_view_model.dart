import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileViewModel(this._profileRepository);

  UserEntity? _user;
  bool _isLoading = false; // hanya untuk memuat profil (spinner layar penuh)
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  // Logout me-reset pohon widget (lihat main.dart); hindari notify setelah dispose.
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
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;

  void clearError() => _errorMessage = null;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> loadUserProfile({bool silent = false}) async {
    final id = _userId;
    if (id == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _user = await _profileRepository.getUserProfile(id);
      if (_user == null) _errorMessage = 'Profile not found';
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Jalankan penyimpanan; true hanya jika benar-benar berhasil.
  Future<bool> _save(
    Future<void> Function() action, {
    String failure = 'Could not save your changes. Please try again.',
    bool avatar = false,
  }) async {
    if (_userId == null) {
      _errorMessage = 'You need to be signed in.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    if (avatar) {
      _isUploadingAvatar = true;
    } else {
      _isSaving = true;
    }
    notifyListeners();

    var ok = false;
    try {
      await action();
      ok = true;
    } catch (e) {
      debugPrint('Profile save error: $e');
      _errorMessage = e.toString().contains('Bucket not found')
          ? 'Photo storage is not set up yet. Run sql/05_profile_module.sql in Supabase.'
          : failure;
    }

    if (ok) await loadUserProfile(silent: true);

    _isSaving = false;
    _isUploadingAvatar = false;
    notifyListeners();
    return ok;
  }

  Future<bool> updateProfile({
    required String fullName,
    required String bio,
    required List<String> favoriteGenres,
    required List<String> favoriteAuthors,
  }) {
    return _save(
      () => _profileRepository.updateProfile(
        _userId!,
        fullName: fullName.trim(),
        bio: bio.trim(),
        favoriteGenres: favoriteGenres,
        favoriteAuthors: favoriteAuthors,
      ),
      failure: 'Could not update your profile. Please try again.',
    );
  }

  /// Layar "Reading Preferences" (login pertama): simpan pilihan + tandai selesai.
  Future<bool> savePreferences({
    required List<String> favoriteGenres,
    required List<String> favoriteAuthors,
  }) {
    return _save(
      () => _profileRepository.updateProfile(
        _userId!,
        favoriteGenres: favoriteGenres,
        favoriteAuthors: favoriteAuthors,
        onboardingCompleted: true,
      ),
      failure: 'Could not save your preferences. Please try again.',
    );
  }

  /// "Skip for now": tandai selesai tanpa mengubah preferensi.
  Future<bool> skipPreferences() {
    return _save(
      () => _profileRepository.updateProfile(_userId!, onboardingCompleted: true),
      failure: 'Something went wrong. Please try again.',
    );
  }

  Future<bool> uploadAvatar(Uint8List bytes, String contentType) {
    return _save(
      () async {
        await _profileRepository.uploadAvatar(_userId!, bytes, contentType);
      },
      failure: 'Could not upload your photo. Please try again.',
      avatar: true,
    );
  }

  Future<bool> removeAvatar() {
    return _save(
      () => _profileRepository.removeAvatar(_userId!),
      failure: 'Could not remove your photo. Please try again.',
      avatar: true,
    );
  }
}
