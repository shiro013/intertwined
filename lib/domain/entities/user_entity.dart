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

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.joinedDate,
    this.favoriteGenres = const [],
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
    );
  }

  @override
  List<Object?> get props => [id, username, email, fullName, avatarUrl, bio, joinedDate, favoriteGenres];
}
