import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/preference_pickers.dart';
import '../widgets/user_avatar.dart';

/// Edit profil lengkap: foto, nama, bio, genre dan penulis favorit.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _maxPhotoBytes =
      2 * 1024 * 1024; // sama dengan batas bucket (2 MB)

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late List<String> _genres;
  late List<String> _authors;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileViewModel>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _genres = [...(user?.favoriteGenres ?? const <String>[])];
    _authors = [...(user?.favoriteAuthors ?? const <String>[])];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  /// Hanya JPG/PNG/WebP yang diterima (sama dengan aturan bucket di database).
  String? _contentTypeOf(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime;
    }

    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> _pickPhoto() async {
    final vm = context.read<ProfileViewModel>();

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (e) {
      _snack('Could not open your photos.', error: true);
      return;
    }
    if (file == null || !mounted) return; // dibatalkan

    final contentType = _contentTypeOf(file);
    if (contentType == null) {
      _snack('Please choose a JPG, PNG or WebP image.', error: true);
      return;
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxPhotoBytes) {
      _snack(
        'That photo is too large. Please choose one under 2 MB.',
        error: true,
      );
      return;
    }

    final ok = await vm.uploadAvatar(bytes, contentType);
    if (!mounted) return;
    _snack(
      ok
          ? 'Profile photo updated'
          : (vm.errorMessage ?? 'Could not upload your photo.'),
      error: !ok,
    );
  }

  Future<void> _removePhoto() async {
    final vm = context.read<ProfileViewModel>();
    final ok = await vm.removeAvatar();
    if (!mounted) return;
    _snack(
      ok
          ? 'Profile photo removed'
          : (vm.errorMessage ?? 'Could not remove your photo.'),
      error: !ok,
    );
  }

  void _showPhotoOptions() {
    final hasPhoto =
        (context.read<ProfileViewModel>().user?.avatarUrl ?? '').isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Choose a photo',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<ProfileViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    final ok = await vm.updateProfile(
      fullName: _nameController.text,
      bio: _bioController.text,
      favoriteGenres: _genres,
      favoriteAuthors: _authors,
    );
    if (!mounted) return;

    if (ok) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      _snack(vm.errorMessage ?? 'Could not update your profile.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.user;
    final busy = vm.isSaving || vm.isUploadingAvatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: busy ? null : _showPhotoOptions,
                        child: UserAvatar(
                          username: user?.username,
                          avatarUrl: user?.avatarUrl,
                          radius: 56,
                        ),
                      ),
                      if (vm.isUploadingAvatar)
                        const SizedBox(
                          width: 112,
                          height: 112,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Change photo',
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                            onPressed: busy ? null : _showPhotoOptions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'JPG, PNG or WebP, up to 2 MB',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v ?? '').trim().length > 50
                      ? 'Use at most 50 characters'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Favorite genres (${_genres.length}/$kMaxGenres)',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                GenreChipPicker(
                  selected: _genres,
                  onChanged: (value) => setState(() => _genres = value),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Favorite authors',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                AuthorTagInput(
                  authors: _authors,
                  onChanged: (value) => setState(() => _authors = value),
                ),
                const SizedBox(height: 32),
                vm.isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: busy ? null : _save,
                          child: const Text('Save changes'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
