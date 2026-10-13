import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? joinedDate;
  final List<String> favoriteGenres;
  final List<String> favoriteAuthors;

  /// false = pengguna baru yang belum mengisi/melewati layar "Reading Preferences".
  final bool onboardingCompleted;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.joinedDate,
    this.favoriteGenres = const [],
    this.favoriteAuthors = const [],
    this.onboardingCompleted = true,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    DateTime? joinedDate,
    List<String>? favoriteGenres,
    List<String>? favoriteAuthors,
    bool? onboardingCompleted,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      joinedDate: joinedDate ?? this.joinedDate,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      favoriteAuthors: favoriteAuthors ?? this.favoriteAuthors,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        avatarUrl,
        bio,
        joinedDate,
        favoriteGenres,
        favoriteAuthors,
        onboardingCompleted,
      ];
}
