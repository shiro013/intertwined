import 'package:equatable/equatable.dart';

/// Review milik satu user untuk satu buku (tabel `reviews` + profil + jumlah like).
class BookReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final int rating;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  const BookReviewEntity({
    required this.id,
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.rating,
    this.text = '',
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  BookReviewEntity copyWith({int? likeCount, bool? likedByMe}) {
    return BookReviewEntity(
      id: id,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      rating: rating,
      text: text,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [id, userId, rating, text, createdAt, likeCount, likedByMe];
}
