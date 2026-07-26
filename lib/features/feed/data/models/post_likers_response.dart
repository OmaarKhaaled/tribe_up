import 'package:json_annotation/json_annotation.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/features/feed/domain/entities/post_liker_entity.dart';

part 'post_likers_response.g.dart';

@JsonSerializable()
class PostLikerModel {
  @JsonKey(name: 'userId', defaultValue: '')
  final String? userId;

  @JsonKey(name: 'userName')
  final String? userName;

  @JsonKey(name: 'username')
  final String? usernameAlt;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'fullName')
  final String? fullName;

  @JsonKey(name: 'profilePictureUrl')
  final String? profilePictureUrl;

  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;

  @JsonKey(name: 'profilePicture')
  final String? profilePicture;

  @JsonKey(name: 'userProfilePicture')
  final String? userProfilePicture;

  @JsonKey(name: 'pictureUrl')
  final String? pictureUrl;

  @JsonKey(name: 'picture')
  final String? picture;

  @JsonKey(name: 'imageUrl')
  final String? imageUrl;

  const PostLikerModel({
    this.userId,
    this.userName,
    this.usernameAlt,
    this.name,
    this.fullName,
    this.profilePictureUrl,
    this.avatarUrl,
    this.profilePicture,
    this.userProfilePicture,
    this.pictureUrl,
    this.picture,
    this.imageUrl,
  });

  factory PostLikerModel.fromJson(Map<String, dynamic> json) =>
      _$PostLikerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostLikerModelToJson(this);

  String get effectiveUsername => (userName != null && userName!.isNotEmpty)
      ? userName!
      : (usernameAlt ?? '');

  String? get effectiveName => name ?? fullName;

  String? get effectiveAvatar {
    final raw =
        profilePictureUrl ??
        profilePicture ??
        userProfilePicture ??
        pictureUrl ??
        avatarUrl ??
        picture ??
        imageUrl;

    if (raw == null || raw.isEmpty || raw == 'null') return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return '${ApiConstants.hubBaseUrl}$raw';
    }
    return '${ApiConstants.hubBaseUrl}/$raw';
  }

  PostLikerEntity toEntity() {
    return PostLikerEntity(
      userId: userId ?? '',
      username: effectiveUsername,
      name: effectiveName,
      profilePictureUrl: effectiveAvatar,
    );
  }
}

@JsonSerializable()
class PostLikersResponse {
  final List<PostLikerModel>? items;
  final int? page;
  final int? pageSize;
  final int? totalCount;
  final bool? hasMore;

  const PostLikersResponse({
    this.items,
    this.page,
    this.pageSize,
    this.totalCount,
    this.hasMore,
  });

  factory PostLikersResponse.fromJson(dynamic json) {
    if (json is List) {
      final itemsList = json
          .map((e) => PostLikerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PostLikersResponse(items: itemsList, totalCount: itemsList.length);
    } else if (json is Map<String, dynamic>) {
      return _$PostLikersResponseFromJson(json);
    }
    return const PostLikersResponse(items: []);
  }

  Map<String, dynamic> toJson() => _$PostLikersResponseToJson(this);
}
