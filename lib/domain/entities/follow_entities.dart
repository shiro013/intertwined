/// Angka ringkasan sebuah profil (dipakai di profil sendiri & profil orang lain).
class ProfileStats {
  final int booksRead;
  final int booksRated;
  final int quotesSaved;
  final int clubsJoined;
  final int followers;
  final int following;

  const ProfileStats({
    this.booksRead = 0,
    this.booksRated = 0,
    this.quotesSaved = 0,
    this.clubsJoined = 0,
    this.followers = 0,
    this.following = 0,
  });

  ProfileStats copyWith({int? followers, int? following}) {
    return ProfileStats(
      booksRead: booksRead,
      booksRated: booksRated,
      quotesSaved: quotesSaved,
      clubsJoined: clubsJoined,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}

/// Ringkasan singkat satu pengguna untuk daftar (followers, following, pencarian).
class UserSummary {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;

  const UserSummary({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
  });
}
