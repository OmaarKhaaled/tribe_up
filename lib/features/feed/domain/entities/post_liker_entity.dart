import 'package:equatable/equatable.dart';

class PostLikerEntity extends Equatable {
  final String userId;
  final String username;
  final String? name;
  final String? profilePictureUrl;

  const PostLikerEntity({
    required this.userId,
    required this.username,
    this.name,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [userId, username, name, profilePictureUrl];
}
