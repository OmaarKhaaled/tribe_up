import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:tribe_up/features/feed/api/api_client/feed_api_client.dart';
import 'package:tribe_up/features/feed/data/models/create_post_response.dart';
import 'package:tribe_up/features/feed/data/models/feed_response.dart';
import 'package:tribe_up/features/feed/data/models/toggle_like_response.dart';
import 'package:tribe_up/features/feed/data/models/post_model.dart';
import 'package:tribe_up/features/feed/data/models/post_likers_response.dart';
import 'package:tribe_up/features/feed/data/data_sources/feed_remote_data_source.dart';

@Injectable(as: FeedRemoteDataSource)
class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final FeedApiClient _apiClient;
  const FeedRemoteDataSourceImpl(this._apiClient);

  @override
  Future<FeedResponse> getFeedPosts({int page = 1, int pageSize = 20}) async {
    return await _apiClient.getFeed(page, pageSize);
  }

  @override
  Future<FeedResponse> getPersonalFeed({
    required String username,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient.getPersonalFeed(username, page, pageSize);
  }

  @override
  Future<FeedResponse> getGroupFeedPosts({
    required int groupId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient.getGroupFeed(groupId, page, pageSize);
  }

  @override
  Future<CreatePostResponse> createPost({
    int? groupId,
    required String caption,
    required int accessibility,
    List<String>? taggedUserIds,
    List<File>? mediaFiles,
  }) async {
    return await _apiClient.createPost(
      groupId,
      caption,
      accessibility,
      taggedUserIds,
      mediaFiles,
    );
  }

  @override
  Future<void> deletePost({required int postId}) async {
    await _apiClient.deletePost(postId);
  }

  @override
  Future<ToggleLikeResponse> toggleLikePost({required int postId}) async {
    return await _apiClient.toggleLikePost(postId);
  }

  @override
  Future<PostModel> getPostById({required int postId}) async {
    return await _apiClient.getPostById(postId);
  }

  @override
  Future<PostLikersResponse> getPostLikes({
    required int postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _apiClient.getPostLikes(postId, page, pageSize);
  }

  @override
  Future<CreatePostResponse> editPost({
    required int postId,
    required String caption,
    int? groupId,
    int? accessibility,
    List<String>? taggedUserIds,
    List<File>? newMediaFiles,
    List<int>? deleteMediaIds,
  }) async {
    final formData = FormData();

    if (groupId != null) {
      formData.fields.add(MapEntry('GroupId', groupId.toString()));
    }

    formData.fields.add(MapEntry('Caption', caption));
    formData.fields.add(
      MapEntry('Accessibility', (accessibility ?? 1).toString()),
    );

    taggedUserIds?.forEach((id) {
      formData.fields.add(MapEntry('TaggedUserIds', id));
    });

    newMediaFiles?.forEach((file) {
      formData.files.add(
        MapEntry(
          'newMediaFiles',
          MultipartFile.fromFileSync(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    });

    deleteMediaIds?.forEach((id) {
      formData.fields.add(MapEntry('deleteMediaIds', id.toString()));
    });

    final response = await _apiClient.editPost(postId, formData);

    return response;
  }
}
