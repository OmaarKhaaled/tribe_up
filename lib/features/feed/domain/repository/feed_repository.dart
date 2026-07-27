import 'dart:io';

import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/features/feed/domain/entities/feed_response_entity.dart';
import 'package:tribe_up/features/feed/domain/entities/post_entity.dart';
import 'package:tribe_up/features/feed/domain/entities/post_liker_entity.dart';

abstract class FeedRepository {
  Future<BaseResponse<FeedResponseEntity>> getFeedPosts({
    int page,
    int pageSize,
  });

  Future<BaseResponse<FeedResponseEntity>> getPersonalFeedPosts({
    required String username,
    int page,
    int pageSize,
  });

  Future<BaseResponse<FeedResponseEntity>> getGroupFeedPosts({
    required int groupId,
    int page,
    int pageSize,
  });

  Future<BaseResponse<PostEntity>> createPost({
    int? groupId,
    required String caption,
    required int accessibility,
    List<String>? taggedUserIds,
    List<File>? mediaFiles,
  });

  Future<BaseResponse<bool>> deletePost({required int postId});

  Future<BaseResponse<({bool isLiked, int likesCount})>> toggleLikePost({
    required int postId,
  });

  Future<BaseResponse<List<PostLikerEntity>>> getPostLikes({
    required int postId,
    int page,
    int pageSize,
  });

  Future<BaseResponse<PostEntity>> editPost({
    required int postId,
    required String caption,
    int? groupId,
    int? accessibility,
    List<String>? taggedUserIds,
    List<File>? newMediaFiles,
    List<int>? deleteMediaIds,
  });

  Future<BaseResponse<PostEntity>> getPostById({required int postId});
}
